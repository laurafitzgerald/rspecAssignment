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
          before(:each) do
             expect(@local_cache_mock).to receive(:get).with('1111')
          end
          context "nor in the remote cache" do
              it "should read it from the d/b and add it to the remote cache and the should add it to the local cache" do 
                 expect(@memcached_mock).to receive(:get).with('v_1111')
                 expect(@database_mock).to receive(:isbnSearch).with('1111').
                                and_return(@book1111)
                 expect(@memcached_mock).to receive(:set).with('v_1111',1)
                 expect(@memcached_mock).to receive(:set).with('1111_1',@book1111.to_cache)
                 expect(@local_cache_mock).to receive(:set).with('1111', {book: @book1111, version: 1})
              end
          end
          context "but it is in the remote cache" do
              it "should use the remote cache version and add it to local cache" do
                 expect(@database_mock).to_not receive(:isbnSearch)
                 expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
                 expect(@memcached_mock).to receive(:get).with('1111_1').
                                                    and_return @book1111.to_cache 
                 expect(@local_cache_mock).to receive(:set).with('1111', {book: @book1111, version: 1})
             end
          end 
        end        
        context "and it is in the local cache" do
           before(:each) do 
              expect(@database_mock).to_not receive(:isbnSearch)
              expect(@memcached_mock).to receive(:get).with("v_1111").and_return 1
           end
           context "and up to date with the remote cache" do
              it "should use the local cache version" do
                expect(@local_cache_mock).to receive(:get).with('1111').and_return({book: @book1111, version: 1})
              end
           end
           context "and not up to date with the remote cache" do
              it "should use the local cache version and update the remote cache" do
                expect(@local_cache_mock).to receive(:get).with('1111').and_return({book: @book1111.to_cache, version: 2})
                expect(@memcached_mock).to receive(:get).with("1111_1").and_return @book1111.to_cache
                expect(@local_cache_mock).to receive(:set).with('1111', {book: @book1111, version: 1})      
              end   
           end   
        end
        after(:each)do 
            @target.isbnSearch '1111'
        end
      end
      context "Given that the book ISBN is not valid" do
        context "it is not found in the local cache" do
          context "nor is it found in the remote cache" do
            context "nor is it found in the database " do 
                it "it should return nil" do 
                  expect(@local_cache_mock).to receive(:get).with('1234')
                  expect(@memcached_mock).to receive(:get).with('v_1234')
                  expect(@database_mock).to receive(:isbnSearch).with('1234')
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
        expect(@database_mock).to receive(:updateBook).with(@book1111)
      end
      context "Given that a valid book is sent to be updated" do
        context "Given there is a book in the database" do
          it "should update the book in the database" do
            expect(@memcached_mock).to receive(:get).with('v_1111')
            #@target.updateBook(@book1111)
          end
        end
        context "now the book is updated in the database" do
          before (:each) do 
            expect(@memcached_mock).to receive(:get).with('v_1111').and_return 1
            expect(@memcached_mock).to receive(:set).with('v_1111', 2 )
            expect(@memcached_mock).to receive(:set).with('1111_2', @book1111.to_cache)
          end
          context "if there is a copy in the remote cache"do
            it "should update the book and version in the remote cache" do
              expect(@local_cache_mock).to receive(:get)
            end
         end
          context "and if there is a copy in the local cache" do
            it "should update the book and version in the local cache" do
              expect(@local_cache_mock).to receive(:get).with(@book1111.isbn).and_return 1
              expect(@local_cache_mock).to receive(:set).with(@book1111.isbn, {book: @updatedBook, version: 2})            
            end
          end 
        end
      end
      context "Given that a valid book is not sent to be updated" do
        context "it is not found in the database" do
          context "nor is it found in the remote cache" do
            context "nor is it found in the local cache" do
              it "should not carry out any updates" do
                expect(@memcached_mock).to receive(:get).with('v_1111')   
              end
            end
          end
        end
      end
      after(:each)do
          @target.updateBook(@book1111)
      end
    end

    describe "#authorSearch" do
      before(:each)do
        @book1112 = Book.new('1112','title 2','author 1',14.99, 'Web Design', 17 )
        @book1113 = Book.new('1113','title 3','author 1',16.99, 'Databases', 23 )
         @authorreport = String.new("{\"books\":[{\"title\":\"title 1\",\"isbn\":\"1111\"},{\"title\":\"title 2\",\"isbn\":\"1112\"},{\"title\":\"title 3\",\"isbn\":\"1113\"}],\"value\":905.4}")
      end
      context "Given that the book author is valid" do
          context "and no authorreport entry is found in the remote cache for this author" do
            it "should read them from the d/b and add the complex object to the remote cache" do

              expect(@memcached_mock).to receive(:get).with('bks_author 1')
              expect(@database_mock).to receive(:authorSearch).with('author 1').and_return [@book1111, @book1112, @book1113]
              expect(@memcached_mock).to receive(:set).with("bks_author 1", '1111,1112,1113')

              expect(@target).to receive(:buildISBNVersionString).with('1111', @book1111).and_return '1111_1'
              expect(@target).to receive(:buildISBNVersionString).with('1112', @book1112).and_return '1112_1'
              expect(@target).to receive(:buildISBNVersionString).with('1113', @book1113).and_return '1113_1'
            end
          end
          before(:each) do 
             @key = "author 1_1111_1_1112_1_1113_1 "
          end
          context "but there are books relating to the author in the remote cache" do
            before(:each) do
              expect(@memcached_mock).to receive(:get).with('bks_author 1').and_return '1111,1112,1113'
              expect(@target).to receive(:buildISBNVersionString).with('1111', nil).and_return '1111_1'
              expect(@target).to receive(:buildISBNVersionString).with('1112', nil).and_return '1112_1'
              expect(@target).to receive(:buildISBNVersionString).with('1113', nil).and_return '1113_1'
            end
            context "if there is a value in the remote cache which matches the complex object key" do 
              it "set result to the remote cache version" do
                expect(@memcached_mock).to receive(:get).with(@key).and_return @authorreport          
              end
            end
            context "if there is no value in the remote cache with matches the complex object key" do 
              it "get the book values from the remote cache and compute and set result to the author report" do
                expect(@memcached_mock).to receive(:get).with(@key)
                expect(@memcached_mock).to receive(:get).with("1111_1").and_return @book1111.to_cache
                expect(@memcached_mock).to receive(:get).with("1112_1").and_return @book1112.to_cache
                expect(@memcached_mock).to receive(:get).with("1113_1").and_return @book1113.to_cache
                expect(@memcached_mock).to receive(:set).with(@key, @authorreport) 
              end
            end
          end
          after(:each)do
            result = @target.authorSearch 'author 1'
            expect(result).to eq JSON.parse @authorreport
          end
        end 
      context "Given that the book author is not valid" do
          context "it is not found in the remote cache" do
            context "nor is it found in the d/b" do
              it "should return nil" do
                  expect(@memcached_mock).to receive(:get).with('bks_someauthor')
                  expect(@database_mock).to receive(:authorSearch).with('someauthor').and_return []
                  expect(@memcached_mock).to receive(:set).with('bks_someauthor', ""), []
                  result = @target.authorSearch "someauthor"
                  expect(result).to eq Hash["books"=> [], "value"=> 0]
              end
            end
        end
      end
    end  
end