class DaoMaker

  def initialize
  
  end

  def camerize(tablename)
    tablename.split("_").map {|word| word.capitalize }.join("")
  end

  #only head char downcase 
  def top_char_downcase(field)
    check_str = field.split("_").map {|word| word.capitalize }.join("")
    head_str = check_str[0].downcase 
    check_str.slice!(0)
    result = head_str + check_str
  end  

  def make_dao(tablename,entity)
    @orginal_tablename = tablename 
    @tablename = camerize(tablename)
    @entity = entity
    @entity_count = entity.length - 1
    make_header
    make_main
  end

#---------------------------------------- make .h file -----------------------------------------------
  def make_header
    fh = open(@tablename+"Dao.h", "w") # write mode

# template begin -----------------------------------------
    template = <<"EOS" 
//  this file created by DaoMaker
//  created at {datetime}
//
#import <Foundation/Foundation.h>
#import "{tablename}Dto.h"

@interface {tablename}Dao : NSObject
-(NSMutableArray *)findAll;
-(BOOL)insert:({tablename}Dto *)dto;

@end
EOS
# template end -------------------------------------------


    template.gsub!("{datetime}", Time.now.to_s)
    template.gsub!("\{tablename\}", @tablename)


    fh.write(template)


    fh.close
  end

#---------------------------------------- make .m file -----------------------------------------------
  def make_main
    fm = open(@tablename+"Dao.m", "w") # write mode
# template begin -----------------------------------------
    template = <<"EOS"
//
//  this file created by DaoMaker
//  created at {datetime}
//
#import "{tablename}Dao.h"
#import "AdamsDbUtil.h"
#import "{tablename}Dto.h"

@implementation {tablename}Dao
- (NSMutableArray *)findAll {
    FMDatabase *db = [AdamsDbUtil getDatabase];
    [db open];
    FMResultSet *rs;
    db.traceExecution = YES;
    NSString *query = @"SELECT "
    {select_sql};
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    @try {
        rs = [db executeQuery:query];
        NSLog(@"ERROR: %d: %@",[db lastErrorCode],[db lastErrorMessage]);
        while ([rs next]) {
            {tablename}Dto *dto = [[{tablename}Dto alloc] init];
{select_to_dto}

            [list addObject:dto];
        }
        return list;
    }
    @finally {
        [rs close];
        [db close];
    }
}

-(BOOL)insert:({tablename}Dto *)dto {
    FMDatabase *db = [AdamsDbUtil getDatabase];
    [db open];

    NSString *query = @"INSERT INTO {orginal_tablename}("
      {insert_property}
    ")";

    db.traceExecution = YES;
    @try {
        if (![db executeUpdate:query,
          {insert_sql}
            NSLog(@"ERROR: %d: %@",[db lastErrorCode],[db lastErrorMessage]);
            return NO;
        } else {
            return YES;
        }
    }
    @finally {
        [db close];
    }
}


@end

EOS
# template end -------------------------------------------

    #make {select_sql}
    select_sql_text = ""
    order_column = ""

    @entity.each_with_index do |column_name,count|
      key = column_name[0]

      if count == 1
        order_column = column_name[0]
      end

      if select_sql_text == ""
        select_sql_text = select_sql_text+          "\""+key+"\""
      else
        select_sql_text = select_sql_text+", \r\n    \""+key+"\""
      end

    end

    select_sql_text = select_sql_text +"\r\n" + "    \"FROM \""+"\r\n"
    select_sql_text = select_sql_text + "    \""+@orginal_tablename+"\"\r\n"
    select_sql_text = select_sql_text + "    \"ORDER BY \"\r\n"
    select_sql_text = select_sql_text + "    \""+order_column+"\""

    #make {select_to_dto}
    select_to_dto_text = ""

    @entity.each do |column_name|
      key = column_name[0]
      downkey = top_char_downcase(key)

      type = column_name[1]
      if type == "TEXT"
        select_to_dto_text = select_to_dto_text + "            dto."+downkey+" = [rs stringForColumn:@\""+key+"\"]);"+"\r\n"
      else
        select_to_dto_text = select_to_dto_text + "            dto."+downkey+" = [rs intForColumn:@\""+key+"\"]);"+"\r\n"
      end
    end



    #make {insert_property}
    insert_property_text = ""

    @entity.each_with_index do |column_name,count|
      key  = column_name[0]
      type =  column_name[1]
      if insert_property_text == ""
        insert_property_text = insert_property_text + "\" " + key 
      else
        insert_property_text = insert_property_text + ",\"\r\n"+ "   \" " + key
      end
    end    

    # matubi no kanma no trim

    insert_property_text = insert_property_text+ "\"\r\n" + "    \") VALUES (\"" 

    @entity.each_with_index do |column_name,count|
      key = column_name[0]


      if (key == "ASYNC_DATETIME") or (key == "CREATE_DATETIME") or (key == "UPDATE_DATETIME")
        if @entity_count == count 
          insert_property_text = insert_property_text + "\r\n"+ "    \"  datetime\(\'now\', \'localtime\'\)\""
        else 
          insert_property_text = insert_property_text + "\r\n"+ "    \"  datetime\(\'now\', \'localtime\'\),\""
        end
      else
        #bad compair way
        if insert_property_text == ""
          insert_property_text = insert_property_text +        +  "    \"  ?,\""
        else
          if @entity_count == count
            insert_property_text = insert_property_text + "\r\n" +  "    \"  ?\""
          else
            insert_property_text = insert_property_text + "\r\n" +  "    \"  ?,\""
          end
        end
      end

    end

    #make {insert_sql}
    insert_sql_text = ""

    @entity.each_with_index do |column_name,count|
      key = column_name[0]
      downkey = top_char_downcase(key)
      if insert_sql_text == ""
        insert_sql_text = insert_sql_text +           "    dto."          +downkey
      else
        insert_sql_text = insert_sql_text + ",\r\n" + "              dto."+downkey
      end
    end



    template.gsub!("{orginal_tablename}", @orginal_tablename)
    template.gsub!("{select_sql}", select_sql_text)
    template.gsub!("{select_to_dto}", select_to_dto_text)
    template.gsub!("\{datetime\}", Time.now.to_s)
    template.gsub!("\{tablename\}", @tablename)
    template.gsub!("{insert_property}", insert_property_text)
    template.gsub!("{insert_sql}", insert_sql_text)


    fm.write(template)
    fm.close
  end


end