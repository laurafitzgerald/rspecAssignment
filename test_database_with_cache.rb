require_relative "./database_with_cache"
require_relative "./local_cache"
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


    describe "#updateBook" do
      before(:each) do
        @updatedBook = Book.new('1111','title 1','author 1',14.99, 'Programming', 20 ) 
        expect(@database_mock).to receive(:updateBook).with(@book1111)#.and_return @updatedBook
      end
      context "Given there is a book in the database" do
        it "should update the book in the database" do
            
            expect(@memcached_mock).to receive(:get).with("v_1111").and_return nil

            #@book1111.price = 14.99
            result = @target.updateBook(@book1111)
            expect(result).to eq nil
        end
        context "if there is a copy in the remote cache"do
          it "it should update the book and version in the remote cache" do
                
                expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
                expect(@memcached_mock).to receive(:set).with('v_1111', 2 )
                expect(@memcached_mock).to receive(:set).with('1111_2', @book1111.to_cache)
                
                result = @target.updateBook @book1111

          end
     
          context "and if there is a copy in the local cache" do
            it "should update the book and version in the local cache" do
             
                expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
                expect(@memcached_mock).to receive(:set).with('v_1111', 2 )
                expect(@memcached_mock).to receive(:set).with('1111_2', @book1111.to_cache)
                #expect_any_instance_of(LocalCache).to_not receive(:get).with(@book1111.isbn)#.and_return 1
                expect_any_instance_of(LocalCache).to receive(:get).with(@book1111.isbn).and_return 1
                expect_any_instance_of(LocalCache).to receive(:set).with(@book1111.isbn, {book: @updatedBook, version: 2})
                
                @target.updateBook @book1111
                result = @local_cache_mock.get '1111'
                expect(result).to eq @updatedBook

            end
          end 


        end 
      end 



    end

    
end