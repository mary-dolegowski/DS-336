/*just for testing to move the dataset in use from CAS to work*/
/* caslib _all_ assign; */

/*these will eventually come from the folder list selected and an interaction with the CDISC API*/
%let dataset = ae_dm;
%let domain = AE;
%let label = Adverse Events;
%let start_time = %sysfunc(datetime(),e8601dz20.);

%let IGD = %sysfunc(CATS(IG., &domain.));

/* moving the cas dataset into work */
data work.&dataset.;
	set public.&dataset.;
run;

/*pull out all the varibles in use in the dataset*/
proc contents data=work.&dataset. 
	out = work.&dataset._contents
	NOPRINT;
run;
proc sort data=work.&dataset._contents;
	by VARNUM;
run;

/*set the observations to a macro var and the modified date to a macro var*/
proc SQL noprint;
	select distinct nobs into :nobs from work.&dataset._contents;
	select distinct strip(put(modate,e8601dz20.)) into :modate	from work.&dataset._contents;
run;
%put &nobs.;
%put &modate.;

/*turn contents into a table to easy set up in JSON*/
data work.&dataset._contents;
	set work.&dataset._contents (Keep = Name Type Length Label VARNUM);
	OID = CATS("IT.", "&domain.",".", Name);
	keySequence = VARNUM;
	if Type = 1 then Type_text = 'integer';
	if Type = 2 then Type_text = 'string';
	drop Type VARNUM;
	rename Type_text=Type;
run;   

data work.&dataset._contents;
	retain OID Name Label Type Length keySequence;
	set work.&dataset._contents;
run;       

proc json out = "/nfsshare/sashls2/data/DatasetJson/datasetJSON_procjsonv11_ae.json";
	write open object;
		write values "datasetJSONCreationDateTime" "&start_time.";
		write values "datasetJSONVersion" "1.1.0";
		write values "fileOID" "www.sponsor.xyz.org.project123.final";
		write values "dbLastModifiedDateTime" "&modate.";
		write values "originator" "Sponsor XYZ";
		write values "sourceSystem";
			write open object;
				write values "name" "Software ABC";
				write values "version" "1.0.0";
			write close;
		write values "studyOID" "xxx";
		write values "metaDataVersionOID" "xxx.y";
		write values "metaDataRef" "https://metadata.location.org/api.link";
		write values "itemGroupOID" "&IGD.";
		write values "records" &nobs.;
		write values "name" "&domain.";
		write values "label" "&label.";
		write values "columns";
			write open array;
				export work.&dataset._contents / keys nosastags;
			write close;
		write values "rows";
			write open array;
				export work.&dataset. / nokeys nosastags trimblanks;
			write close;
	write close;
run;