#pragma once

const QMap<QString, std::vector<std::string>> setDefaultBridges(){
    QMap<QString, std::vector<std::string>> defaultBridges;

    std::vector<QString> types = {"obfs4", "meek-azure", "snowflake"};
    std::vector<QString> types_name = {"obfs4", "meek_lite", "snowflake"};
	
	for(size_t i = 0; i<types.size();i++){
		std::vector<std::string> bridges;
        QFile inputFile("pluggable_transports/bridges.txt");
		if (inputFile.open(QIODevice::ReadOnly))
		{
		   QTextStream in(&inputFile);
		   while (!in.atEnd())
		   {
		      QString line = in.readLine();
		      if(line.split(" ")[0] == types_name[i]){
                bridges.push_back(line.trimmed().toStdString());
		      }
		   }
		   inputFile.close();
           defaultBridges[types[i]] = bridges;
		}
	}
    return defaultBridges;
}

const QMap<QString, std::vector<std::string>> defaultBridges = setDefaultBridges();

const QString recommendedBridgeType = "obfs4";
