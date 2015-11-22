require_relative "./database_with_cache"
require "rspec/mocks"

describe DatabaseWithCache do
  before(:each) do
      @book1111 = Book.new('1111','title 1','author 1',12.99, 'Programming', 20 )
      @memcached_mock = double()
      @database_mock = double()
      @target = DatabaseWithCache.new @database_mock, @memcached_mock 
   end

   describe "#isbnSearch" do
      context "Given the book ISBN is valid" do
        context "and it is not in the local cache" do
          context "nor in the remote cache" do
              it "should read it from the d/b and add it to the remots cache" do
                 expect(@memcached_mock).to receive(:get).with('v_1111').and_return nil
                 expect(@memcached_mock).to receive(:set).with('v_1111',1)
                 expect(@memcached_mock).to receive(:set).with('1111_1',@book1111.to_cache)
                 expect(@database_mock).to receive(:isbnSearch).with('1111').
                                and_return(@book1111)
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
        context "it is in the local cache" do
           context "and up to date with the remote cache" do
              it "should use the local cache version"
          end   
        end
      end
    end



    describe "#authorSearch" do
      context "Given that the book author is valid" do
        context "and it is not in the local cache" do
          context "nor is it in the remote cache" do
            it "should read them from the d/b and add them to the remote cache" do

            end
          end
          context "but they are in the remote cache" do
            it "should use the remote cache version and add it to the local cache" do
            end
          end 

        end 
        context "it is in the local cache" do
          context "and up to date with the remote cache" do
            it "should use the local cache version"
          end
        end
      end
    end
    
    
end