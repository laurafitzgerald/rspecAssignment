require_relative "./database_with_cache"
require_relative "./local_cache"
require "rspec/mocks"

describe DatabaseWithCache do
  before(:each) do
      @book1111 = Book.new('1111','title 1','author 1',12.99, 'Programming', 20 )
      @memcached_mock = double()
      @database_mock = double()
      @local_cache_mock = double(LocalCache)
      @target = DatabaseWithCache.new @database_mock, @memcached_mock 
      @target.instance_variable_set "@local_cache", @local_cache_mock
   end

   describe "#isbnSearch" do
      context "Given the book ISBN is valid" do
        context "and it is not in the local cache" do
          context "nor in the remote cache" do
              it "should read it from the d/b and add it to the remote cacheand the should add it to the local cache" do 
                 expect(@local_cache_mock).to receive(:get).with('1111').and_return nil
                 #expect_any_instance_of(LocalCache).to receive(:get).with('1111').and_return nil
                 expect(@memcached_mock).to receive(:get).with('v_1111').and_return nil
                 expect(@database_mock).to receive(:isbnSearch).with('1111').
                                and_return(@book1111)
                 expect(@memcached_mock).to receive(:set).with('v_1111',1)
                 expect(@memcached_mock).to receive(:set).with('1111_1',@book1111.to_cache)
                 expect(@local_cache_mock).to receive(:set).with('1111', {book: @book1111, version: 1})
                 
                 result = @target.isbnSearch('1111')
                 expect(result).to be @book1111
              end
          end
          context "but it is in the remote cache" do
              it "should use the remote cache version and add it to local cache" do
                 expect(@local_cache_mock).to receive(:get).with('1111').and_return nil
                 expect(@database_mock).to_not receive(:isbnSearch)
                 expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
                 expect(@memcached_mock).to receive(:get).with('1111_1').
                                                    and_return @book1111.to_cache 
                 expect(@local_cache_mock).to receive(:set).with('1111', {book: @book1111, version: 1})

                 result = @target.isbnSearch('1111')
                 expect(result).to eq @book1111
                 expect(@local_cache_mock.get '1111').to_not eq nil

              end
          end 
        end        
        context "and it is in the local cache" do
           context "and up to date with the remote cache" do
              it "should use the local cache version" do
                expect(@database_mock).to_not receive(:isbnSearch)
                expect(@local_cache_mock).to receive(:get).with('1111').and_return({book: @book1111, version: 1})
                expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
                #if memcahce_version.to_i == local_copy[:version] should return true if up to date with the remote cache


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
                expect(@local_cache_mock).to receive(:get).with('1111').and_return Hash["book", @book1111.to_cache, "version", 2]
                #expect_any_instance_of(LocalCache).to receive(:get).with('1111').and_return Hash["book", @book1111.to_cache, "version", 2]
                expect(@memcached_mock).to receive(:get).with("1111_1").and_return @book1111.to_cache
                expect(@local_cache_mock).to receive(:set).with('1111', {book: @book1111, version: 1})
                #expect_any_instance_of(LocalCache).to receive(:set).with('1111', {book: @book1111, version: 2})

                #if memcahce_version.to_i == local_copy[:version] should return false if not up to date with the remote cache


                result = @target.isbnSearch '1111'

              end   
           end   
        end
      end
      context "Given that the book ISBN is not valid" do
        context "it is not found in the local cache" do
          context "nor is it found in the remote cache" do
            context "nor is it found in the database " do 
                it "it should return nil" do 

                  expect(@local_cache_mock).to receive(:get).with('1234').and_return nil
                  #expect_any_instance_of(LocalCache).to receive(:get).with('1234').and_return nil
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
                expect(@local_cache_mock).to receive(:get).with(@book1111.isbn).and_return 1
                expect(@local_cache_mock).to receive(:set).with(@book1111.isbn, {book: @updatedBook, version: 2})
                #expect_any_instance_of(LocalCache).to receive(:get).with(@book1111.isbn).and_return 1
                #expect_any_instance_of(LocalCache).to receive(:set).with(@book1111.isbn, {book: @updatedBook, version: 2})
                
                result = @target.updateBook @book1111
                
                expect(result).to eq @updatedBook

            end
          end 


        end 
      end 



    end

    describe "#authorSearch" do
      context "Given that the book author is valid" do
        context "and it is not in the local cache" do
          context "nor is it in the remote cache" do
            it "should read them from the d/b and add them to the remote cache" #do

            #end
          end
          context "but they are in the remote cache" do
            it "should use the remote cache version and add it to the local cache" #do
            #end
          end 

        end 
        context "it is in the local cache" do
          context "and up to date with the remote cache" do
            it "should use the local cache version"
          end
        end
      end

      context "Given that the book author is not valid" do
        context "it is not found in the local cache" do
          context "nor is it found in the remote cache" do
            context "nor is it found in the d/b" do
              it "should return nil" do

                  expect(@local_cache_mock).to receive(:get).with('bks_someauthor').and_return nil
                  #expect_any_instance_of(LocalCache).to receive(:get).with('bks_someauthor').and_return nil
                  expect(@database_mock).to receive(:authorSearch).with('bks_someauthor').and_return nil
                  expect(@memcached_mock).to receive(:set).with('bks_someauthor'), nil

                  result = @target.authorSearch "someauthor"
                  expect(result).to eq nil


              end

            end
          end
        end
      end

    end

    
end