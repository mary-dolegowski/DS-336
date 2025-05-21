%let start_time = %sysfunc(datetime(),e8601dz20.);

proc cas;
	set stdjson;
	
/*Set the lib and dataset*/	
	libloc = "PUBLIC";
	table = "ae_dm";
	
/*Set some of the details for the metadata, this could also be pulled from the repository*/
	domain = "ae";
	domain_label = "Adverse Events";
	
/*General data extraction and organization to prepare the data for JSON formatting*/
	details_results = CATS("r_", domain);
	columninfo_results = CATS("r_", domain);
	
	table.tableInfo result = details_results /
	name = table, caslib = libloc;
	
/*Calculating the number of rows and oulling the last modified date from the dataset*/
	nrows = details_results.TableInfo[,"rows"];
	last_mod_date_og = details_results.TableInfo[1,"ModTime"];
	last_mod_date = putn(last_mod_date_og, e8601dz20.);
	
	table.fetch result = fetch_results /
		table ={name = table, caslib = libloc},
		INDEX = true,
		to = nrows[1];

/*items = a description of all the variables aka column names and details*/
	table.columninfo result = columninfo_results /
		table ={name = table, caslib = libloc};
	
	i = 1;	
	do row over columninfo_results.ColumnInfo;
		items[i].itemOID = CATS("IT.", domain, ".", row.Column);
		items[i].name = row.Column;
		items[i].label = row.Label;
		items[i].dataType = row.Type;
		items[i].length = row.FormattedLength;
		items[i].keySequence = i;
		i = i + 1;
	end;
	
/*itemData - a list of all the values*/
	do row over fetch_results.fetch;
		new_row = getvalues(row);
		loc = new_row[1];
		itemDataTble[loc] = new_row;
	end;

/*sourceSystem*/
	sourceSystem.name = "Software ABC";
	sourceSystem.version = "1.0.0";
/*Metadata*/
	DatasetJSON.datasetJSONCreationDateTime = "&start_time.";
	DatasetJSON.datasetJSONVersion = "1.1.0";
	DatasetJSON.fileOID = "www.sponsor.xyz.org.project123.final";
	DatasetJSON.dbLastModifiedDateTime = last_mod_date;
	DatasetJSON.originator = "Sponsor XYZ";
	DatasetJSON.sourceSystem = sourceSystem;
	DatasetJSON.studyOID = "xxx";
    DatasetJSON.metaDataVersionOID = "xxx.y";
    DatasetJSON.metaDataRef = "https://metadata.location.org/api.link";
    DatasetJSON.records = nrows[1];
    DatasetJSON.name = domain;
    DatasetJSON.label = domain_label;
    DatasetJSON.columns = items;
    DatasetJSON.rows = itemDataTble;

/*final clean up of the JSON dataset*/
	final = casl2json(DatasetJSON);
/*remove any extra spaces*/
	final = compbl(final);
	
	file outfile "/nfsshare/sashls2/data/DatasetJson/datasetJSON_C2J_V11.json";
	print final;
	
run;




