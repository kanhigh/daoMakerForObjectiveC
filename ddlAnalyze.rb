class DdlAnalyze 

  def initialize

    puts ARGV[0]

  end

  def analyzeFile(filename)

    #init
    start_flg = 0
    element_hash = Hash::new

    table_arry = []

    entity_hash = Hash.new
 
    # open args[0]
    file = open(filename)



    file.each do |line|

      # CREATE TABLE LINE
      if /^CREATE TABLE / =~ line
        
        element_hash = Hash.new
        element_hash.store("table", line.sub(/^CREATE TABLE /,"").sub(/\r\n/,""))
        next
      end

      # ( only LINE: this line is key to start
      if /^\(/ =~ line
        entity_hash = Hash.new
        start_flg = 1
        next
      end

      # SQL comment LINE
      if /^--/ =~ line
        next
      end


      # this line is target
      if start_flg == 1
        # except line
        if (/^\);/ =~ line) or (/^PRIMARY KEY/ =~ line) or (/^FOREIGN/ =~ line) or (/^REFERENCES/ =~ line)

        else
          line = line.sub(/,/,"").sub(/\r\n/, "")
          entity_object = line.split(" ") 
          entity_hash[entity_object[0]] = entity_object[1]
        end
      end

      # ); only LINE : this line is key to end
      if /^\);/ =~ line
        element_hash.store("entity", entity_hash)
        table_arry.push(element_hash)
        start_flg = 0
        next
      end

    end

    file.close

    return table_arry

  end

end
