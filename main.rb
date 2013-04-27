require_relative 'DdlAnalyze'
require_relative 'DtoMaker'
require_relative 'DaoMaker'

daoMaker = DdlAnalyze.new
analyze_arry = daoMaker.analyzeFile(ARGV[0])

analyze_arry.each do |check|
  dtoMaker = DtoMaker.new
  dtoMaker.make_dto(check["table"],check["entity"])
  daoMaker = DaoMaker.new
  daoMaker.make_dao(check["table"],check["entity"])
end

