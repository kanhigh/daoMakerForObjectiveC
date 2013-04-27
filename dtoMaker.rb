class DtoMaker

  def initialize

  end

  # camerize is filename convert
  def camerize(tablename)
    tablename.split("_").map {|word| word.capitalize }.join("")
  end

  # this is make dto : .h and .m 
  def make_dto(tablename,entity) 
    @tablename = camerize(tablename)
    @entity = entity
    make_header
    make_main
  end

#---------------------------------------- make .h file -----------------------------------------------
  def make_header
    fh = open(@tablename+"Dto.h", "w") # write mode

# template begin ----------------------------------------
    template = <<"EOS" 
//
//  this file created by DtoMaker
//  created at {datetime}
//
#import <Foundation/Foundation.h>

@interface {tablename}Dto : NSObject
{property}
@end
EOS
# template end -------------------------------------------


    property_text = ""
    @entity.each do |column_name|
      key  = column_name[0]
      type =  column_name[1]
      
      if type == "TEXT"
        property_text = property_text + "@property (nonatomic, copy) NSString *"+ key +";\r\n"
      elsif type == "INTEGER"
        property_text = property_text + "@property (nonatomic) int "+ key +";\r\n"
      end
        
    end

    template.gsub!("{datetime}", Time.now.to_s)
    template.gsub!("\{tablename\}", @tablename)
    template.gsub!("{property}", property_text)


    fh.write(template)


    fh.close
  end

#---------------------------------------- make .m file -----------------------------------------------
  def make_main
    fm = open(@tablename+"Dto.m", "w") # write mode
# template begin ----------------------------------------
    template = <<"EOS"
//  this file created by DtoMaker
//  created at {datetime}
//
#import "{tablename}Dto.h"

@implementation {tablename}Dto

@end

EOS
# template end -------------------------------------------

    template.gsub!("\{datetime\}", Time.now.to_s)
    template.gsub!("\{tablename\}", @tablename)
    fm.write(template)
    fm.close
  end

end
