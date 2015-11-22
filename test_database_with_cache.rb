require_relative "./database_with_cache"
require "rspec/mocks"

describe DatabaseWithCache do
  before(:each) do
      @book1111 = Book.new('1111','title 1','author 1',12.99, 'Programming', 20 )
      @memcached_mock = double()
      @database_mock = double()
      @local_cache_mock = double()
      #allow(LocalCache).to receive(:initialize).and_return(@local_cache_mock)
      #allow(@local_cache_mock).to receive(:set)
      #allow(@local_cache_mock).to receive(:get).with('1111').and_return(@book1111)
      #@local_cache = Local_cache.new
      #@local_cache.stub(:new).and_return({})
      @target = DatabaseWithCache.new @database_mock, @memcached_mock 
   end

   describe "#isbnSearch" do
      context "Given the book ISBN is valid" do
        context "and it is not in the local cache" do
          context "nor in the remote cache" do
              it "should read it from the d/b and add it to the remote cacheand the should add it to the local cache" do #should add to the local cache as well
                 expect_any_instance_of(LocalCache).to receive(:get).with('1111').and_return nil
                 expect(@memcached_mock).to receive(:get).with('v_1111').and_return nil
                 expect(@database_mock).to receive(:isbnSearch).with('1111').
                                and_return(@book1111)
                 expect(@memcached_mock).to receive(:set).with('v_1111',1)
                 expect(@memcached_mock).to receive(:set).with('1111_1',@book1111.to_cache)
                 result = @target.isbnSearch('1111')
                 expect(result).to be @book1111
              end
          end
          context "but it is in the remote cache" do
              it "should use the remote cache version and add it to local cache" do
                 expect(@database_mock).to_not receive(:isbnSearch)
                 expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
                 expect(@memcached_mock).to receive(:get).with('1111_1').
                                                    and_return @book1111.to_cache 
                 result = @target.isbnSearch('1111')
                 expect(result).to eq @book1111
                 # Check it's in local cache 
              end
          end 
        end        
        context "and it is in the local cache" do
           context "and up to date with the remote cache" do
              it "should use the local cache version" do
                expect_any_instance_of(LocalCache).to receive(:get).with('1111').and_return Hash["book", @book1111.to_cache, "version", 1]
                expect(@memcached_mock).to receive(:get).with('v_1111').and_return "1"
                result = @target.isbnSearch '1111'
                expect(result).to eq @book1111
              end
           end
           before(:each)do
             @book1111version2 = Book.new('1111','title 1','author 1',14.99, 'Programming', 20 )
           end
           context "and not up to date with the remote cache" do
              it "should use the local cache version and update the remote cache" do
                
                expect(@memcached_mock).to receive(:get).with("v_1111").and_return "1"
                expect_any_instance_of(LocalCache).to receive(:get).with('1111').and_return Hash["book", @book1111.to_cache, "version", 2]
                expect(@memcached_mock).to receive(:get).with("1111_1").and_return @book1111.to_cache
                expect_any_instance_of(LocalCache).to receive(:set).with('1111', {book: @book1111, version: 2})

              end   
           end   
        end
      end
      context "Given that the book ISBN is not valid" do
        context "it is not found in the local cache" do
          context "nor is it found in the remote cache" do
            context "nor is it found in the database " do 
                it "it should return nil" do 

                  expect_any_instance_of(LocalCache).to receive(:get).with('1234').and_return nil
                  expect(@memcached_mock).to receive(:get).with('v_1234').and_return nil
                  expect(@database_mock).to receive(:isbnSearch).with('1234').and_return nil

                  result = @target.isbnSearch('1234')
                  expect(result).to be nil
                end
              end
            end
          end
        end
      end

  
    
end