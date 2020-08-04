use strict;
use warnings;  

#=========================================================================================================
#	Modules
#=========================================================================================================
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';
use XML::LibXML;
use Tk;
use Cwd;

#=========================================================================================================
#	Administrative informations 
#=========================================================================================================
our $VERSION   = '1.1.0';
our $COMPANY   = '';
our $AUTHOR    = '';
#=========================================================================================================
#=========================================================================================================

#===================================
# Constants
#===================================

$Win32::OLE::Warn = 3;

#=END Constants=====================

#===================================
# Global variables
#===================================
my $scriptFileName                = "GenerateTestCaseTPT_GUI.pl";
my @InterfacesDOCMISC             = (); 
my @InterfacesARXML               = (); 
my @missingInterfaces             = ();
my $tpt                  		  = '';
my $docmisc                       = '';
my %outputMappingsRun             = ();
my %outputMappingsInit            = ();
my %outputParameterMappingsRun    = ();
my %outputParameterMappingsInit   = ();
my %MappingType9Run               = ();
my %MappingType9Init              = ();
my %MappingType4Run               = ();
my %MappingType4Init              = ();
my %writeRteMappingsRun           = ();
my %writeRteMappingsInit          = ();
my %writeRteParameterMappingsRun  = ();
my %writeRteParameterMappingsInit = ();
my %simpleWriteRteMappingsRun     = ();
my %simpleWriteRteMappingsInit    = ();
my %inputMappingsRun              = ();
my %inputMappingsInit             = ();
my %readRteMappingsRun            = ();
my %readRteMappingsInit           = ();
my %simpleReadRteMappingsRun      = ();
my %simpleReadRteMappingsInit     = ();


#=END Global variables==============

#===================================
# Script
#===================================

print "\n--------------------------------------------------------------\n";
print "\n$scriptFileName(v$VERSION) Started ..\n\n";
print "Hello, Welcome to the Test Case Generation Tool!\n";     
print "-----------------------------------------------------------------\n";
my $ScriptPath = $0;
$ScriptPath =~ s/$scriptFileName$//;

my $FCName = "";
my $tpt_new = "";
my $new_tpt = "";

my $dir = getcwd;


#===================================
# Creating GUI
#===================================
		$tpt = get_first_file("tpt_template.tpt");
		$tpt = $dir.'/'.$tpt;
		$docmisc = get_first_file(".xls");
		$FCName = $docmisc;
		$FCName =~ s{\.[^.]+$}{};  
		$docmisc = $dir.'/'.$docmisc;
		print "[INFO]: tpt file to update is: $tpt.\n"; 
		print "[INFO]: docmisc file to update is: $docmisc.\n";
		ButRefStart_push();
MainLoop;
#===================================
# Functions
#===================================
sub get_first_file {
	my $ext = shift =~ s/.*\.//r;
	+(<*.$ext>)[0];
}

sub ButRefStart_push {
  $tpt_new = $FCName;
  #$tpt_new =~ s{\.[^.]+$}{};  
  
  #Create a log file
  my $NameFileLog = $dir.'/'.$FCName.'_GenTPT.log';
  unless(open (OUTPUTFILE, '>', $NameFileLog)) 
  {
    die "\nUnable to create $NameFileLog\n";
  } 
  
  print OUTPUTFILE "Log for TPT Test Case Generation \n";
  print OUTPUTFILE "--------------------------------------------------------\n";
  
  readDOCMISC($docmisc);  
  if(createTestCase($tpt))
  {
    print "Test Case Created";
	  exit;
  }
  else
  {
    print "Error while reading tpt templet File";
	  exit;
  }	

}

#exit;

#===================================
# Functions
#===================================
sub readDOCMISC
{
  my ($file) = @_;
  return unless -f $file;
  return unless $file =~ /.+\.xls$/;
  print "Reading DOCMISC...\n";  
  my $Excel = Win32::OLE->GetActiveObject('Excel.Application') || Win32::OLE->new('Excel.Application', 'Quit');    
  print "The DOCMISC you have selected is: ", $file," \n";  
  my $Book = $Excel->Workbooks->open($file); 
  my $Sheet = $Book->Worksheets('Mapping');  
  my $ProviderIndex = 0;
  my $ReceiverIndex = 0;
  
  foreach my $row (3..1200) #Presently only 500 rows are considered.
  {
    foreach my $col (2)
    { 
	    next unless defined $Sheet->Cells($row,$col)->{'Value'};
      
      # Parse output mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+28)->{'Value'} ne '4') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run') )
      {
        my @outputDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};  
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $outputDetails[0]=$input;   
        $outputDetails[1]=$inputScaling;
        $outputDetails[2]=$inputType;
        $outputDetails[3]=$inputUnit;
        $outputDetails[4]=$output;     
        $outputDetails[5]=$outputScaling;  
        $outputDetails[6]=$outputType;    
        $outputDetails[7]=$outputUnit;       
        $outputDetails[8]=$inputMin;  
        $outputDetails[9]=$inputMax;  
        $outputDetails[10]=$outputMin;  
        $outputDetails[11]=$outputMax;    
        $outputDetails[12]=$inputOffset;  
        $outputDetails[13]=$outputOffset;   
		    $outputDetails[14]=$task;  
				$outputDetails[15]=$mappingType;
				$outputDetails[16]=$ADDmappingType;
        push(@{$outputMappingsRun{$variableName}}, @outputDetails);  
      }	 
			
			# Parse output mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+28)->{'Value'} ne '4') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init') )
      {
        my @outputDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};       
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};    
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $outputDetails[0]=$input;   
        $outputDetails[1]=$inputScaling;
        $outputDetails[2]=$inputType;
        $outputDetails[3]=$inputUnit;
        $outputDetails[4]=$output;     
        $outputDetails[5]=$outputScaling;  
        $outputDetails[6]=$outputType;    
        $outputDetails[7]=$outputUnit;       
        $outputDetails[8]=$inputMin;  
        $outputDetails[9]=$inputMax;  
        $outputDetails[10]=$outputMin;  
        $outputDetails[11]=$outputMax;    
        $outputDetails[12]=$inputOffset;  
        $outputDetails[13]=$outputOffset;   
		    $outputDetails[14]=$task;  
				$outputDetails[15]=$mappingType;
				$outputDetails[16]=$ADDmappingType;
        push(@{$outputMappingsInit{$variableName}}, @outputDetails);  
      }
      
	  # Parse mapping type 4 in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+28)->{'Value'} eq '4') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run') )
      {
        my @outputDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};       
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};    
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $outputDetails[0]=$input;   
        $outputDetails[1]=$inputScaling;
        $outputDetails[2]=$inputType;
        $outputDetails[3]=$inputUnit;
        $outputDetails[4]=$output;     
        $outputDetails[5]=$outputScaling;  
        $outputDetails[6]=$outputType;    
        $outputDetails[7]=$outputUnit;       
        $outputDetails[8]=$inputMin;  
        $outputDetails[9]=$inputMax;  
        $outputDetails[10]=$outputMin;  
        $outputDetails[11]=$outputMax;    
        $outputDetails[12]=$inputOffset;  
        $outputDetails[13]=$outputOffset;   
		    $outputDetails[14]=$task;  
				$outputDetails[15]=$mappingType;
				$outputDetails[16]=$ADDmappingType;
        push(@{$MappingType4Run{$variableName}}, @outputDetails);  
      }	
	  
	  # Parse mapping type 4 in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+28)->{'Value'} eq '4') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init') )
      {
        my @outputDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};       
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};    
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $outputDetails[0]=$input;   
        $outputDetails[1]=$inputScaling;
        $outputDetails[2]=$inputType;
        $outputDetails[3]=$inputUnit;
        $outputDetails[4]=$output;     
        $outputDetails[5]=$outputScaling;  
        $outputDetails[6]=$outputType;    
        $outputDetails[7]=$outputUnit;       
        $outputDetails[8]=$inputMin;  
        $outputDetails[9]=$inputMax;  
        $outputDetails[10]=$outputMin;  
        $outputDetails[11]=$outputMax;    
        $outputDetails[12]=$inputOffset;  
        $outputDetails[13]=$outputOffset;   
		    $outputDetails[14]=$task;  
				$outputDetails[15]=$mappingType;
				$outputDetails[16]=$ADDmappingType;
        push(@{$MappingType4Init{$variableName}}, @outputDetails);  
      }
	  
      # Parse output Parameter mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} eq 'Parameter') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run'))
      {
        my @outputParDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};      
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $outputParDetails[0]=$input;   
        $outputParDetails[1]=$inputScaling;
        $outputParDetails[2]=$inputType;
        $outputParDetails[3]=$inputUnit;
        $outputParDetails[4]=$output;     
        $outputParDetails[5]=$outputScaling;  
        $outputParDetails[6]=$outputType;    
        $outputParDetails[7]=$outputUnit;    
        $outputParDetails[8]=$inputMin;  
        $outputParDetails[9]=$inputMax;  
        $outputParDetails[10]=$outputMin;  
        $outputParDetails[11]=$outputMax;     
        $outputParDetails[12]=$inputOffset;  
        $outputParDetails[13]=$outputOffset;  
		    $outputParDetails[14]=$task; 
				$outputParDetails[15]=$mappingType;
				$outputParDetails[16]=$ADDmappingType;
        push(@{$outputParameterMappingsRun{$variableName}}, @outputParDetails);  
      }
			
			# Parse output Parameter mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} eq 'Parameter') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init'))
      {
        my @outputParDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};      
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $outputParDetails[0]=$input;   
        $outputParDetails[1]=$inputScaling;
        $outputParDetails[2]=$inputType;
        $outputParDetails[3]=$inputUnit;
        $outputParDetails[4]=$output;     
        $outputParDetails[5]=$outputScaling;  
        $outputParDetails[6]=$outputType;    
        $outputParDetails[7]=$outputUnit;    
        $outputParDetails[8]=$inputMin;  
        $outputParDetails[9]=$inputMax;  
        $outputParDetails[10]=$outputMin;  
        $outputParDetails[11]=$outputMax;     
        $outputParDetails[12]=$inputOffset;  
        $outputParDetails[13]=$outputOffset;  
		    $outputParDetails[14]=$task; 
				$outputParDetails[15]=$mappingType;
				$outputParDetails[16]=$ADDmappingType;
        push(@{$outputParameterMappingsInit{$variableName}}, @outputParDetails);  
      }
      
      # Parse Mapping Type 9 in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && 
         ($Sheet->Cells($row,$col+15)->{'Value'} eq '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run'))
      {
        my @outputParDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};        
        my $output = $Sheet->Cells($row,$col)->{'Value'};         
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};  
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};        
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputValue = $Sheet->Cells($row,$col+27)->{'Value'};           
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};         
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};      
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};  
        $outputParDetails[4]=$output;     
        $outputParDetails[5]=$outputScaling;  
        $outputParDetails[6]=$outputType;    
        $outputParDetails[7]=$outputUnit;    
        $outputParDetails[8]=$inputValue; 
        $outputParDetails[10]=$outputMin;  
        $outputParDetails[11]=$outputMax; 
        $outputParDetails[13]=$outputOffset;  
		    $outputParDetails[14]=$task; 
				$outputParDetails[15]=$mappingType;
				$outputParDetails[16]=$ADDmappingType;
				
        push(@{$MappingType9Run{$variableName}}, @outputParDetails);  
      }
      
      # Parse Mapping Type 9 in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Output') && 
         ($Sheet->Cells($row,$col+15)->{'Value'} eq '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init'))
      {
        my @outputParDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};        
        my $output = $Sheet->Cells($row,$col)->{'Value'};         
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};  
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};        
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputValue = $Sheet->Cells($row,$col+27)->{'Value'};           
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};         
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};      
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};  
        $outputParDetails[4]=$output;     
        $outputParDetails[5]=$outputScaling;  
        $outputParDetails[6]=$outputType;    
        $outputParDetails[7]=$outputUnit;    
        $outputParDetails[8]=$inputValue; 
        $outputParDetails[10]=$outputMin;  
        $outputParDetails[11]=$outputMax; 
        $outputParDetails[13]=$outputOffset;  
		    $outputParDetails[14]=$task; 
				$outputParDetails[15]=$mappingType;
				$outputParDetails[16]=$ADDmappingType;
        push(@{$MappingType9Init{$variableName}}, @outputParDetails);  
      }
			
			
      
      # Parse WriteRte mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'WriteRte') && 
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run'))
      {
        my @writeRteDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};				
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};  
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};     
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		my $task = $Sheet->Cells($row,$col+36)->{'Value'};
		my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
		my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
				
        $writeRteDetails[0]=$input;   
        $writeRteDetails[1]=$inputScaling;
        $writeRteDetails[2]=$inputType;
        $writeRteDetails[3]=$inputUnit;
        $writeRteDetails[4]=$output."_RTE";     
        $writeRteDetails[5]=$outputScaling;  
        $writeRteDetails[6]=$outputType;    
        $writeRteDetails[7]=$outputUnit;     
        $writeRteDetails[8]=$inputMin;  
        $writeRteDetails[9]=$inputMax;  
        $writeRteDetails[10]=$outputMin;  
        $writeRteDetails[11]=$outputMax;   
        $writeRteDetails[12]=$inputOffset;  
        $writeRteDetails[13]=$outputOffset; 
		$writeRteDetails[14]=$task;  
	    $writeRteDetails[15]=$mappingType;
		$writeRteDetails[16]=$ADDmappingType;
        push(@{$writeRteMappingsRun{$variableName}}, @writeRteDetails);
      }     
			
			# Parse WriteRte mappings in INit
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'WriteRte') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init'))
      {
        my @writeRteDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};				
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};  
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};     
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $writeRteDetails[0]=$input;   
        $writeRteDetails[1]=$inputScaling;
        $writeRteDetails[2]=$inputType;
        $writeRteDetails[3]=$inputUnit;
        $writeRteDetails[4]=$output."_RTE";     
        $writeRteDetails[5]=$outputScaling;  
        $writeRteDetails[6]=$outputType;    
        $writeRteDetails[7]=$outputUnit;     
        $writeRteDetails[8]=$inputMin;  
        $writeRteDetails[9]=$inputMax;  
        $writeRteDetails[10]=$outputMin;  
        $writeRteDetails[11]=$outputMax;   
        $writeRteDetails[12]=$inputOffset;  
        $writeRteDetails[13]=$outputOffset; 
		    $writeRteDetails[14]=$task;  
				$writeRteDetails[15]=$mappingType;
				$writeRteDetails[16]=$ADDmappingType;
        push(@{$writeRteMappingsInit{$variableName}}, @writeRteDetails);
      }

      # Parse WriteRte Parameter mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'WriteRte') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} eq 'Parameter') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run'))
      {
        my @writeRteParDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $writeRteParDetails[0]=$input;   
        $writeRteParDetails[1]=$inputScaling;
        $writeRteParDetails[2]=$inputType;
        $writeRteParDetails[3]=$inputUnit;
        $writeRteParDetails[4]=$output."_RTE";     
        $writeRteParDetails[5]=$outputScaling;  
        $writeRteParDetails[6]=$outputType;    
        $writeRteParDetails[7]=$outputUnit;   
        $writeRteParDetails[8]=$inputMin;  
        $writeRteParDetails[9]=$inputMax;  
        $writeRteParDetails[10]=$outputMin;  
        $writeRteParDetails[11]=$outputMax;      
        $writeRteParDetails[12]=$inputOffset;  
        $writeRteParDetails[13]=$outputOffset;   
		    $writeRteParDetails[14]=$task;  	
        $writeRteParDetails[15]=$mappingType;
				$writeRteParDetails[16]=$ADDmappingType;				
        push(@{$writeRteParameterMappingsRun{$variableName}}, @writeRteParDetails);
      }  
			
			# Parse Simple WriteRte Parameter mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'WriteRte') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} eq 'Parameter') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init'))
      {
        my @writeRteParDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col+15)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+19)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $inputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $writeRteParDetails[0]=$input;   
        $writeRteParDetails[1]=$inputScaling;
        $writeRteParDetails[2]=$inputType;
        $writeRteParDetails[3]=$inputUnit;
        $writeRteParDetails[4]=$output."_RTE";     
        $writeRteParDetails[5]=$outputScaling;  
        $writeRteParDetails[6]=$outputType;    
        $writeRteParDetails[7]=$outputUnit;   
        $writeRteParDetails[8]=$inputMin;  
        $writeRteParDetails[9]=$inputMax;  
        $writeRteParDetails[10]=$outputMin;  
        $writeRteParDetails[11]=$outputMax;      
        $writeRteParDetails[12]=$inputOffset;  
        $writeRteParDetails[13]=$outputOffset;   
		    $writeRteParDetails[14]=$task;  	
        $writeRteParDetails[15]=$mappingType;
				$writeRteParDetails[16]=$ADDmappingType;				
        push(@{$writeRteParameterMappingsInit{$variableName}}, @writeRteParDetails);
      }

      # Parse Simple WriteRte mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'WriteRte') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+15)->{'Value'} eq '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run'))
      {
        my @writeRteSimpleDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $writeRteSimpleDetails[0]=$output;   
        $writeRteSimpleDetails[1]=$inputScaling;
        $writeRteSimpleDetails[2]=$inputType;
        $writeRteSimpleDetails[3]=$inputUnit;
        $writeRteSimpleDetails[4]=$output."_RTE";     
        $writeRteSimpleDetails[5]=$outputScaling;  
        $writeRteSimpleDetails[6]=$outputType;    
        $writeRteSimpleDetails[7]=$outputUnit;   
        $writeRteSimpleDetails[8]=$inputMin;  
        $writeRteSimpleDetails[9]=$inputMax;  
        $writeRteSimpleDetails[10]=$outputMin;  
        $writeRteSimpleDetails[11]=$outputMax;      
        $writeRteSimpleDetails[12]=$inputOffset;  
        $writeRteSimpleDetails[13]=$outputOffset;    
		    $writeRteSimpleDetails[14]=$task; 	
        $writeRteSimpleDetails[15]=$mappingType;
				$writeRteSimpleDetails[16]=$ADDmappingType;				
        push(@{$simpleWriteRteMappingsRun{$variableName}}, @writeRteSimpleDetails);
      } 
			
			# Parse Simple WriteRte mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'WriteRte') &&
         ($Sheet->Cells($row,$col+16)->{'Value'} ne 'Parameter') && ($Sheet->Cells($row,$col+15)->{'Value'} eq '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init'))
      {
        my @writeRteSimpleDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'}; 
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};
        my $outputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'};   
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $writeRteSimpleDetails[0]=$output;   
        $writeRteSimpleDetails[1]=$inputScaling;
        $writeRteSimpleDetails[2]=$inputType;
        $writeRteSimpleDetails[3]=$inputUnit;
        $writeRteSimpleDetails[4]=$output."_RTE";     
        $writeRteSimpleDetails[5]=$outputScaling;  
        $writeRteSimpleDetails[6]=$outputType;    
        $writeRteSimpleDetails[7]=$outputUnit;   
        $writeRteSimpleDetails[8]=$inputMin;  
        $writeRteSimpleDetails[9]=$inputMax;  
        $writeRteSimpleDetails[10]=$outputMin;  
        $writeRteSimpleDetails[11]=$outputMax;      
        $writeRteSimpleDetails[12]=$inputOffset;  
        $writeRteSimpleDetails[13]=$outputOffset;    
		    $writeRteSimpleDetails[14]=$task; 	
        $writeRteSimpleDetails[15]=$mappingType;
				$writeRteSimpleDetails[16]=$ADDmappingType;				
        push(@{$simpleWriteRteMappingsInit{$variableName}}, @writeRteSimpleDetails);
      } 
	  

      # Parse Input mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Input') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init')	)
      {
        my @inputDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col+15)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'}; 
        my $outputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $outputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputUnit= $Sheet->Cells($row,$col+19)->{'Value'};
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $outputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $inputDetails[0]=$input;   
        $inputDetails[1]=$inputScaling;
        $inputDetails[2]=$inputType;
        $inputDetails[3]=$inputUnit;
        $inputDetails[4]=$output;     
        $inputDetails[5]=$outputScaling;  
        $inputDetails[6]=$outputType;    
        $inputDetails[7]=$outputUnit;   
        $inputDetails[8]=$inputMin;  
        $inputDetails[9]=$inputMax;  
        $inputDetails[10]=$outputMin;  
        $inputDetails[11]=$outputMax;      
        $inputDetails[12]=$inputOffset;  
        $inputDetails[13]=$outputOffset;   
		    $inputDetails[14]=$task; 		
				$inputDetails[15]=$mappingType;
				$inputDetails[16]=$ADDmappingType;
				if( exists ($inputMappingsInit{$variableName}))
				{
				  print OUTPUTFILE "WARNING: Multiple Mappings for same varibale. Handle the case Manually for $variableName\n";
				}
				else
				{
				  push(@{$inputMappingsInit{$variableName}}, @inputDetails);		
				}
      }

      # Parse Input mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'Input') && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') &&
         ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run')	)
      {
        my @inputDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col+15)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'}; 
        my $outputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $outputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputUnit= $Sheet->Cells($row,$col+19)->{'Value'};
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $outputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+23)->{'Value'};   
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $inputDetails[0]=$input;   
        $inputDetails[1]=$inputScaling;
        $inputDetails[2]=$inputType;
        $inputDetails[3]=$inputUnit;
        $inputDetails[4]=$output;     
        $inputDetails[5]=$outputScaling;  
        $inputDetails[6]=$outputType;    
        $inputDetails[7]=$outputUnit;   
        $inputDetails[8]=$inputMin;  
        $inputDetails[9]=$inputMax;  
        $inputDetails[10]=$outputMin;  
        $inputDetails[11]=$outputMax;      
        $inputDetails[12]=$inputOffset;  
        $inputDetails[13]=$outputOffset;   
		    $inputDetails[14]=$task; 		
				$inputDetails[15]=$mappingType;
				$inputDetails[16]=$ADDmappingType;
				if( exists ($inputMappingsRun{$variableName}))
				{
				  print OUTPUTFILE "WARNING: Multiple Mappings for same variable. Handle the case Manually for $variableName\n";
				}
				else
				{
				  push(@{$inputMappingsRun{$variableName}}, @inputDetails);		
				}
      }			
	  
      # Parse ReadRTE mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'ReadRte') 
	     && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init'))
      {
        my @readRteDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col+15)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'}; 
        my $outputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $outputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputUnit= $Sheet->Cells($row,$col+19)->{'Value'};
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'}; 
        my $outputMin = $Sheet->Cells($row,$col+22)->{'Value'};
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+23)->{'Value'};        
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $readRteDetails[0]=$input."_RTE";   
        $readRteDetails[1]=$inputScaling;
        $readRteDetails[2]=$inputType;
        $readRteDetails[3]=$inputUnit;
        $readRteDetails[4]=$output;     
        $readRteDetails[5]=$outputScaling;  
        $readRteDetails[6]=$outputType;    
        $readRteDetails[7]=$outputUnit;   
        $readRteDetails[8]=$inputMin;  
        $readRteDetails[9]=$inputMax;  
        $readRteDetails[10]=$outputMin;  
        $readRteDetails[11]=$outputMax;      
        $readRteDetails[12]=$inputOffset;  
        $readRteDetails[13]=$outputOffset;      
		    $readRteDetails[14]=$task;		
				$readRteDetails[15]=$mappingType;
				$readRteDetails[16]=$ADDmappingType;
				if( exists ($readRteMappingsInit{$variableName}))
				{
				  print OUTPUTFILE "WARNING: Multiple Mappings for same variable. Handle the case Manually for $variableName\n";
				}
				else
				{
				  push(@{$readRteMappingsInit{$variableName}}, @readRteDetails);
				}
      }  	
			
			# Parse ReadRTE mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'ReadRte') 
	     && ($Sheet->Cells($row,$col+15)->{'Value'} ne '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run'))
      {
        my @readRteDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col+15)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'}; 
        my $outputType = $Sheet->Cells($row,$col+18)->{'Value'};
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $outputScaling = $Sheet->Cells($row,$col+21)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputUnit= $Sheet->Cells($row,$col+19)->{'Value'};
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};   
        my $outputMin = $Sheet->Cells($row,$col+22)->{'Value'};   
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+23)->{'Value'};
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $readRteDetails[0]=$input."_RTE";   
        $readRteDetails[1]=$inputScaling;
        $readRteDetails[2]=$inputType;
        $readRteDetails[3]=$inputUnit;
        $readRteDetails[4]=$output;     
        $readRteDetails[5]=$outputScaling;  
        $readRteDetails[6]=$outputType;    
        $readRteDetails[7]=$outputUnit;   
        $readRteDetails[8]=$inputMin;  
        $readRteDetails[9]=$inputMax;  
        $readRteDetails[10]=$outputMin;  
        $readRteDetails[11]=$outputMax;      
        $readRteDetails[12]=$inputOffset;  
        $readRteDetails[13]=$outputOffset;      
		    $readRteDetails[14]=$task;		
				$readRteDetails[15]=$mappingType;
				$readRteDetails[16]=$ADDmappingType;
				if( exists ($readRteMappingsRun{$variableName}))
				{
				  print OUTPUTFILE "WARNING: Multiple Mappings for same variable. Handle the case Manually for $variableName\n";
				}
				else
				{
				  push(@{$readRteMappingsRun{$variableName}}, @readRteDetails);
				}
      }

      # Parse Simple ReadRTE mappings in Init
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'ReadRte') &&
	       ($Sheet->Cells($row,$col+15)->{'Value'} eq '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Init') )
      {
        my @readRteSimpleDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'}; 
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputUnit= $Sheet->Cells($row,$col+5)->{'Value'};
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};        
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};   
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $readRteSimpleDetails[0]=$input."_RTE";   
        $readRteSimpleDetails[1]=$inputScaling;
        $readRteSimpleDetails[2]=$inputType;
        $readRteSimpleDetails[3]=$inputUnit;
        $readRteSimpleDetails[4]=$input;     
        $readRteSimpleDetails[5]=$outputScaling;  
        $readRteSimpleDetails[6]=$outputType;    
        $readRteSimpleDetails[7]=$outputUnit;   
        $readRteSimpleDetails[8]=$inputMin;  
        $readRteSimpleDetails[9]=$inputMax;  
        $readRteSimpleDetails[10]=$outputMin;  
        $readRteSimpleDetails[11]=$outputMax;      
        $readRteSimpleDetails[12]=$inputOffset;  
        $readRteSimpleDetails[13]=$outputOffset;       
		    $readRteSimpleDetails[14]=$task; 
				$readRteSimpleDetails[15]=$mappingType;
				$readRteSimpleDetails[16]=$ADDmappingType;
				if( exists ($simpleReadRteMappingsInit{$variableName}))
				{
				  print OUTPUTFILE "WARNING: Multiple Mappings for same variable. Handle the case Manually for $variableName\n";
				}
				else
				{
				  push(@{$simpleReadRteMappingsInit{$variableName}}, @readRteSimpleDetails);
				}
      } 
			
			
			# Parse Simple ReadRTE mappings in Run
      if(($Sheet->Cells($row,$col-1)->{'Value'} ne 'Remove') && ($Sheet->Cells($row,$col+14)->{'Value'} eq 'ReadRte') &&
	       ($Sheet->Cells($row,$col+15)->{'Value'} eq '-') && ($Sheet->Cells($row,$col+36)->{'Value'} eq 'Run') )
      {
        my @readRteSimpleDetails = ();
        my $variableName = $Sheet->Cells($row,$col)->{'Value'};
        my $output = $Sheet->Cells($row,$col)->{'Value'};
        my $input = $Sheet->Cells($row,$col)->{'Value'}; 
        my $outputType = $Sheet->Cells($row,$col+4)->{'Value'};
        my $inputType = $Sheet->Cells($row,$col+4)->{'Value'};   
        my $outputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($outputScaling =~ m/E/)
		{$outputScaling = sprintf("%.5f", $outputScaling);}
        my $inputScaling = $Sheet->Cells($row,$col+7)->{'Value'};
		if($inputScaling =~ m/E/)
		{$inputScaling = sprintf("%.5f", $inputScaling);}
        my $outputUnit= $Sheet->Cells($row,$col+5)->{'Value'};
        my $inputUnit = $Sheet->Cells($row,$col+5)->{'Value'};  
        my $outputMin = $Sheet->Cells($row,$col+8)->{'Value'};  
		if($outputMin =~ m/E/)
		{$outputMin = sprintf("%.5f", $outputMin);}
        my $outputMax = $Sheet->Cells($row,$col+9)->{'Value'};				
		if($outputMax =~ m/E/)
		{$outputMax = sprintf("%.5f", $outputMax);}
        my $inputMin = $Sheet->Cells($row,$col+8)->{'Value'};
		if($inputMin =~ m/E/)
		{$inputMin = sprintf("%.5f", $inputMin);}
        my $inputMax = $Sheet->Cells($row,$col+9)->{'Value'}; 
		if($inputMax =~ m/E/)
		{$inputMax = sprintf("%.5f", $inputMax);}
        my $outputOffset = $Sheet->Cells($row,$col+24)->{'Value'};
		if($outputOffset =~ m/E/)
		{$outputOffset = sprintf("%.5f", $outputOffset);}
        my $inputOffset = $Sheet->Cells($row,$col+10)->{'Value'};
		if($inputOffset =~ m/E/)
		{$inputOffset = sprintf("%.5f", $inputOffset);}
		    my $task = $Sheet->Cells($row,$col+36)->{'Value'};
				my $mappingType = $Sheet->Cells($row,$col+28)->{'Value'};
				my $ADDmappingType = $Sheet->Cells($row,$col+29)->{'Value'};
        $readRteSimpleDetails[0]=$input."_RTE";   
        $readRteSimpleDetails[1]=$inputScaling;
        $readRteSimpleDetails[2]=$inputType;
        $readRteSimpleDetails[3]=$inputUnit;
        $readRteSimpleDetails[4]=$input;     
        $readRteSimpleDetails[5]=$outputScaling;  
        $readRteSimpleDetails[6]=$outputType;    
        $readRteSimpleDetails[7]=$outputUnit;   
        $readRteSimpleDetails[8]=$inputMin;  
        $readRteSimpleDetails[9]=$inputMax;  
        $readRteSimpleDetails[10]=$outputMin;  
        $readRteSimpleDetails[11]=$outputMax;      
        $readRteSimpleDetails[12]=$inputOffset;  
        $readRteSimpleDetails[13]=$outputOffset;       
		    $readRteSimpleDetails[14]=$task; 
				$readRteSimpleDetails[15]=$mappingType;
				$readRteSimpleDetails[16]=$ADDmappingType;
				if( exists ($simpleReadRteMappingsRun{$variableName}))
				{
				  print OUTPUTFILE "WARNING: Multiple Mappings for same variable. Handle the case Manually for $variableName\n";
				}
				else
				{
				  push(@{$simpleReadRteMappingsRun{$variableName}}, @readRteSimpleDetails);
				}
      }	  
    }
  }  
  $Book->Close; 
}

#===================================
# Functions
#===================================
sub createTestCase
{
  my ($file) = @_;
  return unless -f $file;
  return unless $file =~ /.+\.tpt$/;
  print "Parsing $file...\n";
  my $parser = XML::LibXML->new();
  $parser->keep_blanks(0);
  my $document = $parser->parse_file($file);
  my $element = $document->getDocumentElement();  	
  $element = modifyTestCase($element, $file);	  	
  $new_tpt = $tpt_new."_Simple.tpt";  
  $document->toFile($new_tpt, 1);  
  return 1;
}

sub modifyTestCase
{
  my ($element, $file) = @_;     	
  print "\n ---------------------------------\n";
  print "[INFO]: Creating TPT Test case file \n $file..\n";
  print "------------------------------------\n";	
  addChannels($element, $file); 
  addParameter($element, $file);
  addMinMax($element, $file);
  addScaling($element, $file);
  AddInputOutput($element, $file);
  AddInitTestCase($element, $file);
  AddRunTestCase($element, $file);
}

sub addChannels
{
  my ($element, $file) = @_; 
  foreach my $mapping(keys %outputMappingsRun) 
  #Add Channels for Output Mapping
  {
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $channel2 = XML::LibXML::Element->new("channel");
    my $inputName = (@{$outputMappingsRun{$mapping}})[0];   
    my $inputScaling = (@{$outputMappingsRun{$mapping}})[1];      
    my $inputType = getTptType((@{$outputMappingsRun{$mapping}})[2]); 
    my $inputUnit = (@{$outputMappingsRun{$mapping}})[3];   
    my $outputName = (@{$outputMappingsRun{$mapping}})[4];   
    my $outputScaling = (@{$outputMappingsRun{$mapping}})[5];      
    my $outputType = getTptType((@{$outputMappingsRun{$mapping}})[6]); 
    my $outputUnit = (@{$outputMappingsRun{$mapping}})[7];    
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    $channel2->setAttribute('log'=>'true');
    $channel2->setAttribute('name'=>$outputName);
    if($outputType ne 'B_TRUE')
    {
      $channel2->setAttribute('scaling'=>"0 1 0 0 0 $outputScaling");
    }
    $channel2->setAttribute('type'=>$outputType);
    $channel2->setAttribute('unit'=>$outputUnit);
    $channel2->setAttribute('value'=>'0.0');
    my @channels = $element->getElementsByTagName("channels");
    my @channelNames = $channels[0]->getElementsByTagName("channel");
	  foreach my $chnnelName(@channelNames)
	  {
	    if($chnnelName->getAttribute('name') eq $channel1 )
	    {
	      #Nothing to do
		    next;
	    }
	    else
	    {
	      $channels[0]->addChild($channel1);    		   
	    }
    }
		#$channels[0]->addChild($channel1); 
		
		foreach my $chnnelName(@channelNames)
	  {
	    if($chnnelName->getAttribute('name') eq $channel2 )
	    {
	      #Nothing to do
		    next;
	    }
	    else
	    {
	      $channels[0]->addChild($channel2);    		   
	    }
	  }
		#$channels[0]->addChild($channel2);
  }   

  foreach my $mapping(keys %writeRteMappingsRun) 
  #Add Channels for writeRteMappingsRun Mapping
  {
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $channel2 = XML::LibXML::Element->new("channel");
    my $inputName = (@{$writeRteMappingsRun{$mapping}})[0];   
    my $inputScaling = (@{$writeRteMappingsRun{$mapping}})[1];      
    my $inputType = getTptType((@{$writeRteMappingsRun{$mapping}})[2]); 
    my $inputUnit = (@{$writeRteMappingsRun{$mapping}})[3];   
    my $outputName = (@{$writeRteMappingsRun{$mapping}})[4];   
    my $outputScaling = (@{$writeRteMappingsRun{$mapping}})[5];      
    my $outputType = getTptType((@{$writeRteMappingsRun{$mapping}})[6]); 
    my $outputUnit = (@{$writeRteMappingsRun{$mapping}})[7];    
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    $channel2->setAttribute('log'=>'true');
    $channel2->setAttribute('name'=>$outputName);
    if($outputType ne 'B_TRUE')
    {
      $channel2->setAttribute('scaling'=>"0 1 0 0 0 $outputScaling");
    }
    $channel2->setAttribute('type'=>$outputType);
    $channel2->setAttribute('unit'=>$outputUnit);
    $channel2->setAttribute('value'=>'0.0');
    my @channels = $element->getElementsByTagName("channels");   
		my @channelNames = $channels[0]->getElementsByTagName("channel");
		foreach my $chnnelName(@channelNames)
	  {
	    if($chnnelName->getAttribute('name') eq $channel1 )
	    {
	      #Nothing to do
		    next;
	    }
	    else
	    {
	      $channels[0]->addChild($channel1);   		   
	    }
    }
    #$channels[0]->addChild($channel1);    
		foreach my $chnnelName(@channelNames)
	  {
	    if($chnnelName->getAttribute('name') eq $channel2 )
	    {
	      #Nothing to do
		    next;
	    }
	    else
	    {
	      $channels[0]->addChild($channel2);    		   
	    }
    }
    #$channels[0]->addChild($channel2);  
  }  
  
  foreach my $mapping(keys %readRteMappingsRun) 
  #Add Channels for readRteMappingsRun Mapping
  {
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $channel2 = XML::LibXML::Element->new("channel");
    my $inputName = (@{$readRteMappingsRun{$mapping}})[0];   
    my $inputScaling = (@{$readRteMappingsRun{$mapping}})[1];      
    my $inputType = getTptType((@{$readRteMappingsRun{$mapping}})[2]); 
    my $inputUnit = (@{$readRteMappingsRun{$mapping}})[3];   
    my $outputName = (@{$readRteMappingsRun{$mapping}})[4];   
    my $outputScaling = (@{$readRteMappingsRun{$mapping}})[5];      
    my $outputType = getTptType((@{$readRteMappingsRun{$mapping}})[6]); 
    my $outputUnit = (@{$readRteMappingsRun{$mapping}})[7];    
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    $channel2->setAttribute('log'=>'true');
    $channel2->setAttribute('name'=>$outputName);
    if($outputType ne 'B_TRUE')
    {
      $channel2->setAttribute('scaling'=>"0 1 0 0 0 $outputScaling");
    }
    $channel2->setAttribute('type'=>$outputType);
    $channel2->setAttribute('unit'=>$outputUnit);
    $channel2->setAttribute('value'=>'0.0');
    my @channels = $element->getElementsByTagName("channels");   
    #$channels[0]->addChild($channel1);    
    #$channels[0]->addChild($channel2);  
  } 
  
  foreach my $mapping(keys %outputParameterMappingsRun) 
  #Add Channels for outputParameterMappingsRun Mapping
  {
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $inputName = (@{$outputParameterMappingsRun{$mapping}})[4];   
    my $inputScaling = (@{$outputParameterMappingsRun{$mapping}})[5];      
    my $inputType = getTptType((@{$outputParameterMappingsRun{$mapping}})[6]); 
    my $inputUnit = (@{$outputParameterMappingsRun{$mapping}})[7];      
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    my @channels = $element->getElementsByTagName("channels");   
    #$channels[0]->addChild($channel1);    
  }
 
  foreach my $mapping(keys %writeRteParameterMappingsRun) 
  #Add Channels for writeRteParameterMappingsRun Mapping
  {
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $inputName = (@{$writeRteParameterMappingsRun{$mapping}})[4];   
    my $inputScaling = (@{$writeRteParameterMappingsRun{$mapping}})[5];      
    my $inputType = getTptType((@{$writeRteParameterMappingsRun{$mapping}})[6]); 
    my $inputUnit = (@{$writeRteParameterMappingsRun{$mapping}})[7];      
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    my @channels = $element->getElementsByTagName("channels");   
    #$channels[0]->addChild($channel1);    
  }

  
  foreach my $mapping(keys %inputMappingsRun) 
  {
	#Add Channel for input Mapping
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $channel2 = XML::LibXML::Element->new("channel");
    my $inputName = (@{$inputMappingsRun{$mapping}})[0];   
    my $inputScaling = (@{$inputMappingsRun{$mapping}})[1];      
    my $inputType = getTptType((@{$inputMappingsRun{$mapping}})[2]); 
    my $inputUnit = (@{$inputMappingsRun{$mapping}})[3];   
    my $outputName = (@{$inputMappingsRun{$mapping}})[4];   
    my $outputScaling = (@{$inputMappingsRun{$mapping}})[5];      
    my $outputType = getTptType((@{$inputMappingsRun{$mapping}})[6]); 
    my $outputUnit = (@{$inputMappingsRun{$mapping}})[7];    
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    $channel2->setAttribute('log'=>'true');
    $channel2->setAttribute('name'=>$outputName);
    if($outputType ne 'B_TRUE')
    {
      $channel2->setAttribute('scaling'=>"0 1 0 0 0 $outputScaling");
    }
    $channel2->setAttribute('type'=>$outputType);
    $channel2->setAttribute('unit'=>$outputUnit);
    $channel2->setAttribute('value'=>'0.0');
    my @channels = $element->getElementsByTagName("channels");   
    #$channels[0]->addChild($channel1);    
    #$channels[0]->addChild($channel2);  
  }  

foreach my $mapping(keys %simpleWriteRteMappingsRun) 
  {
	#Add Channel for simpleWriteRteMappingsRun Mapping
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $channel2 = XML::LibXML::Element->new("channel");
    my $inputName = (@{$simpleWriteRteMappingsRun{$mapping}})[0];   
    my $inputScaling = (@{$simpleWriteRteMappingsRun{$mapping}})[1];      
    my $inputType = getTptType((@{$simpleWriteRteMappingsRun{$mapping}})[2]); 
    my $inputUnit = (@{$simpleWriteRteMappingsRun{$mapping}})[3];   
    my $outputName = (@{$simpleWriteRteMappingsRun{$mapping}})[4];   
    my $outputScaling = (@{$simpleWriteRteMappingsRun{$mapping}})[5];      
    my $outputType = getTptType((@{$simpleWriteRteMappingsRun{$mapping}})[6]); 
    my $outputUnit = (@{$simpleWriteRteMappingsRun{$mapping}})[7];    
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    $channel2->setAttribute('log'=>'true');
    $channel2->setAttribute('name'=>$outputName);
    if($outputType ne 'B_TRUE')
    {
      $channel2->setAttribute('scaling'=>"0 1 0 0 0 $outputScaling");
    }
    $channel2->setAttribute('type'=>$outputType);
    $channel2->setAttribute('unit'=>$outputUnit);
    $channel2->setAttribute('value'=>'0.0');
    my @channels = $element->getElementsByTagName("channels");   
    #$channels[0]->addChild($channel1);    
    #$channels[0]->addChild($channel2);  
  }

foreach my $mapping(keys %simpleReadRteMappingsRun) 
  {
	#Add Channel for simpleReadRteMappingsRun Mapping
    #Create Channel    
    my $channel1 = XML::LibXML::Element->new("channel");		
    my $channel2 = XML::LibXML::Element->new("channel");
    my $inputName = (@{$simpleReadRteMappingsRun{$mapping}})[0];   
    my $inputScaling = (@{$simpleReadRteMappingsRun{$mapping}})[1];      
    my $inputType = getTptType((@{$simpleReadRteMappingsRun{$mapping}})[2]); 
    my $inputUnit = (@{$simpleReadRteMappingsRun{$mapping}})[3];   
    my $outputName = (@{$simpleReadRteMappingsRun{$mapping}})[4];   
    my $outputScaling = (@{$simpleReadRteMappingsRun{$mapping}})[5];      
    my $outputType = getTptType((@{$simpleReadRteMappingsRun{$mapping}})[6]); 
    my $outputUnit = (@{$simpleReadRteMappingsRun{$mapping}})[7];    
    $channel1->setAttribute('log'=>'true'); 
    $channel1->setAttribute('name'=>$inputName);    
    if($inputType ne 'B_TRUE')
    {    
      $channel1->setAttribute('scaling'=>"0 1 0 0 0 $inputScaling");
    }
    $channel1->setAttribute('type'=>$inputType);
    $channel1->setAttribute('unit'=>$inputUnit);
    $channel1->setAttribute('value'=>'0.0');    
    $channel2->setAttribute('log'=>'true');
    $channel2->setAttribute('name'=>$outputName);
    if($outputType ne 'B_TRUE')
    {
      $channel2->setAttribute('scaling'=>"0 1 0 0 0 $outputScaling");
    }
    $channel2->setAttribute('type'=>$outputType);
    $channel2->setAttribute('unit'=>$outputUnit);
    $channel2->setAttribute('value'=>'0.0');
    my @channels = $element->getElementsByTagName("channels");   
    #$channels[0]->addChild($channel1);    
    #$channels[0]->addChild($channel2);  
  }  
}

sub addParameter
{
  my ($element, $file) = @_; 
  foreach my $outputParMapping(keys %outputParameterMappingsRun) 
  {
  #Add Parameter for Output Mapping
    my $parameter = XML::LibXML::Element->new("parameter");	    
    my $parameterName = (@{$outputParameterMappingsRun{$outputParMapping}})[0];   
    my $parameterScaling = (@{$outputParameterMappingsRun{$outputParMapping}})[1];      
    my $parameterType = getTptType((@{$outputParameterMappingsRun{$outputParMapping}})[2]); 
    my $parameterUnit = (@{$outputParameterMappingsRun{$outputParMapping}})[3];       
    $parameter->setAttribute('exchangeMode'=>'exchange'); 
    $parameter->setAttribute('name'=>$parameterName); 
    if($parameterType ne 'B_TRUE')
    {
      $parameter->setAttribute('scaling'=>"0 1 0 0 0 $parameterScaling");
    }
    $parameter->setAttribute('type'=>$parameterType);
    $parameter->setAttribute('unit'=>$parameterUnit);
    $parameter->setAttribute('value'=>'0.0');       
    my @Parameters = $element->getElementsByTagName("parameters");   
    $Parameters[0]->addChild($parameter); 
  }
  
  foreach my $writeRteParMappings(keys %writeRteParameterMappingsRun) 
  {
	#Add Parameter for writeRtePar Mapping
    my $parameter = XML::LibXML::Element->new("parameter");	    
    my $parameterName = (@{$writeRteParameterMappingsRun{$writeRteParMappings}})[0];   
    my $parameterScaling = (@{$writeRteParameterMappingsRun{$writeRteParMappings}})[1];      
    my $parameterType = getTptType((@{$writeRteParameterMappingsRun{$writeRteParMappings}})[2]); 
    my $parameterUnit = (@{$writeRteParameterMappingsRun{$writeRteParMappings}})[3];       
    $parameter->setAttribute('exchangeMode'=>'exchange'); 
    $parameter->setAttribute('name'=>$parameterName); 
    if($parameterType ne 'B_TRUE')
    {
      $parameter->setAttribute('scaling'=>"0 1 0 0 0 $parameterScaling");
    }
    $parameter->setAttribute('type'=>$parameterType);
    $parameter->setAttribute('unit'=>$parameterUnit);
    $parameter->setAttribute('value'=>'0.0');       
    my @Parameters = $element->getElementsByTagName("parameters");   
    #$Parameters[0]->addChild($parameter);        
  }
  
}

sub addMinMax
{
  my ($element, $file) = @_; 
  foreach my $outputParMapping(keys %outputMappingsRun) 
  #Add MinMax for Output Mapping
  {
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$outputMappingsRun{$outputParMapping}})[0]; 
    my $inputMin = (@{$outputMappingsRun{$outputParMapping}})[8];   
    my $inputMax = (@{$outputMappingsRun{$outputParMapping}})[9]; 
    my $output = (@{$outputMappingsRun{$outputParMapping}})[4];     
    my $outputMin = (@{$outputMappingsRun{$outputParMapping}})[10]; 
    my $outputMax = (@{$outputMappingsRun{$outputParMapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  }
  
  foreach my $outputParameterMapping(keys %outputParameterMappingsRun) 
  {
	#Add MinMax for outputParameter Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$outputParameterMappingsRun{$outputParameterMapping}})[0]; 
    my $inputMin = (@{$outputParameterMappingsRun{$outputParameterMapping}})[8];   
    my $inputMax = (@{$outputParameterMappingsRun{$outputParameterMapping}})[9]; 
    my $output = (@{$outputParameterMappingsRun{$outputParameterMapping}})[4];     
    my $outputMin = (@{$outputParameterMappingsRun{$outputParameterMapping}})[10]; 
    my $outputMax = (@{$outputParameterMappingsRun{$outputParameterMapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  }

  
  foreach my $writeRteParameterMapping(keys %writeRteParameterMappingsRun) 
  {
    #Add MinMax for writeRteParameter Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$writeRteParameterMappingsRun{$writeRteParameterMapping}})[0]; 
    my $inputMin = (@{$writeRteParameterMappingsRun{$writeRteParameterMapping}})[8];   
    my $inputMax = (@{$writeRteParameterMappingsRun{$writeRteParameterMapping}})[9]; 
    my $output = (@{$writeRteParameterMappingsRun{$writeRteParameterMapping}})[4];     
    my $outputMin = (@{$writeRteParameterMappingsRun{$writeRteParameterMapping}})[10]; 
    my $outputMax = (@{$writeRteParameterMappingsRun{$writeRteParameterMapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  }

  foreach my $writeRteParameterMapping(keys %writeRteMappingsRun) 
  {
    #Add MinMax for writeRteMappingsRun Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$writeRteMappingsRun{$writeRteParameterMapping}})[0]; 
    my $inputMin = (@{$writeRteMappingsRun{$writeRteParameterMapping}})[8];   
    my $inputMax = (@{$writeRteMappingsRun{$writeRteParameterMapping}})[9]; 
    my $output = (@{$writeRteMappingsRun{$writeRteParameterMapping}})[4];     
    my $outputMin = (@{$writeRteMappingsRun{$writeRteParameterMapping}})[10]; 
    my $outputMax = (@{$writeRteMappingsRun{$writeRteParameterMapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  }
  
  foreach my $inputMapping(keys %inputMappingsRun) 
  {
  #Add MinMax for input Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$inputMappingsRun{$inputMapping}})[0]; 
    my $inputMin = (@{$inputMappingsRun{$inputMapping}})[8];   
    my $inputMax = (@{$inputMappingsRun{$inputMapping}})[9]; 
    my $output = (@{$inputMappingsRun{$inputMapping}})[4];     
    my $outputMin = (@{$inputMappingsRun{$inputMapping}})[10]; 
    my $outputMax = (@{$inputMappingsRun{$inputMapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  
  }

foreach my $Mapping(keys %readRteMappingsRun) 
  {
  #Add MinMax for readRteMappingsRun Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$readRteMappingsRun{$Mapping}})[0]; 
    my $inputMin = (@{$readRteMappingsRun{$Mapping}})[8];   
    my $inputMax = (@{$readRteMappingsRun{$Mapping}})[9]; 
    my $output = (@{$readRteMappingsRun{$Mapping}})[4];     
    my $outputMin = (@{$readRteMappingsRun{$Mapping}})[10]; 
    my $outputMax = (@{$readRteMappingsRun{$Mapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  
  }

  foreach my $Mapping(keys %readRteMappingsRun) 
  {
  #Add MinMax for readRteMappingsRun Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$readRteMappingsRun{$Mapping}})[0]; 
    my $inputMin = (@{$readRteMappingsRun{$Mapping}})[8];   
    my $inputMax = (@{$readRteMappingsRun{$Mapping}})[9]; 
    my $output = (@{$readRteMappingsRun{$Mapping}})[4];     
    my $outputMin = (@{$readRteMappingsRun{$Mapping}})[10]; 
    my $outputMax = (@{$readRteMappingsRun{$Mapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  
  }
  foreach my $Mapping(keys %readRteMappingsRun) 
  {
  #Add MinMax for readRteMappingsRun Mapping
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $input = (@{$readRteMappingsRun{$Mapping}})[0]; 
    my $inputMin = (@{$readRteMappingsRun{$Mapping}})[8];   
    my $inputMax = (@{$readRteMappingsRun{$Mapping}})[9]; 
    my $output = (@{$readRteMappingsRun{$Mapping}})[4];     
    my $outputMin = (@{$readRteMappingsRun{$Mapping}})[10]; 
    my $outputMax = (@{$readRteMappingsRun{$Mapping}})[11]; 
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'Min'); 
    $flavorattr1->setAttribute('value'=>$inputMin);  
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'Max'); 
    $flavorattr2->setAttribute('value'=>$inputMax);   
    $flavorattr3->setAttribute('decl'=>$output); 
    $flavorattr3->setAttribute('name'=>'Min'); 
    $flavorattr3->setAttribute('value'=>$outputMin);  
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'Max'); 
    $flavorattr4->setAttribute('value'=>$outputMax);    
    my @flavorMinMax = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorMinMax)
    {
      if($minMax->getAttribute("type") eq "Min/Max")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);
        #$minMax->addChild($flavorattr4);
      }
    }
  
  }
}

sub addScaling
{
  my ($element, $file) = @_; 
  foreach my $outputParMapping(keys %outputMappingsRun) 
  #Add Scaling for Output Mapping
  {
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$outputMappingsRun{$outputParMapping}})[0]; 
    my $inputExtType = getExtType((@{$outputMappingsRun{$outputParMapping}})[2]); 
    my $inputSlop = (@{$outputMappingsRun{$outputParMapping}})[1]; 
    my $inputBias = getBias((@{$outputMappingsRun{$outputParMapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$outputMappingsRun{$outputParMapping}})[4]; 
    my $outputExtType = getExtType((@{$outputMappingsRun{$outputParMapping}})[6]); 
    my $outputSlop = (@{$outputMappingsRun{$outputParMapping}})[5]; 
    my $outputBias = getBias((@{$outputMappingsRun{$outputParMapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  }
  
  foreach my $inputMapping(keys %inputMappingsRun) 
  {
  #Add scaling for input mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$inputMappingsRun{$inputMapping}})[0]; 
    my $inputExtType = getExtType((@{$inputMappingsRun{$inputMapping}})[2]); 
    my $inputSlop = (@{$inputMappingsRun{$inputMapping}})[1]; 
    my $inputBias = getBias((@{$inputMappingsRun{$inputMapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$inputMappingsRun{$inputMapping}})[4]; 
    my $outputExtType = getExtType((@{$inputMappingsRun{$inputMapping}})[6]); 
    my $outputSlop = (@{$inputMappingsRun{$inputMapping}})[5]; 
    my $outputBias = getBias((@{$inputMappingsRun{$inputMapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  }

  foreach my $writeRteParMapping(keys %writeRteParameterMappingsRun) 
  {
  #Add scaling for writeRteParameterMappingsRun mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$writeRteParameterMappingsRun{$writeRteParMapping}})[0]; 
    my $inputExtType = getExtType((@{$writeRteParameterMappingsRun{$writeRteParMapping}})[2]); 
    my $inputSlop = (@{$writeRteParameterMappingsRun{$writeRteParMapping}})[1]; 
    my $inputBias = getBias((@{$writeRteParameterMappingsRun{$writeRteParMapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$writeRteParameterMappingsRun{$writeRteParMapping}})[4]; 
    my $outputExtType = getExtType((@{$writeRteParameterMappingsRun{$writeRteParMapping}})[6]); 
    my $outputSlop = (@{$writeRteParameterMappingsRun{$writeRteParMapping}})[5]; 
    my $outputBias = getBias((@{$writeRteParameterMappingsRun{$writeRteParMapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  } 

  foreach my $writeRteParMapping(keys %writeRteMappingsRun) 
  {
  #Add scaling for writeRteMappingsRun mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$writeRteMappingsRun{$writeRteParMapping}})[0]; 
    my $inputExtType = getExtType((@{$writeRteMappingsRun{$writeRteParMapping}})[2]); 
    my $inputSlop = (@{$writeRteMappingsRun{$writeRteParMapping}})[1]; 
    my $inputBias = getBias((@{$writeRteMappingsRun{$writeRteParMapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$writeRteMappingsRun{$writeRteParMapping}})[4]; 
    my $outputExtType = getExtType((@{$writeRteMappingsRun{$writeRteParMapping}})[6]); 
    my $outputSlop = (@{$writeRteMappingsRun{$writeRteParMapping}})[5]; 
    my $outputBias = getBias((@{$writeRteMappingsRun{$writeRteParMapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  } 
 foreach my $Mapping(keys %readRteMappingsRun) 
  {
  #Add scaling for readRteMappingsRun mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$readRteMappingsRun{$Mapping}})[0]; 
    my $inputExtType = getExtType((@{$readRteMappingsRun{$Mapping}})[2]); 
    my $inputSlop = (@{$readRteMappingsRun{$Mapping}})[1]; 
    my $inputBias = getBias((@{$readRteMappingsRun{$Mapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$readRteMappingsRun{$Mapping}})[4]; 
    my $outputExtType = getExtType((@{$readRteMappingsRun{$Mapping}})[6]); 
    my $outputSlop = (@{$readRteMappingsRun{$Mapping}})[5]; 
    my $outputBias = getBias((@{$readRteMappingsRun{$Mapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  }
 foreach my $Mapping(keys %simpleWriteRteMappingsRun) 
  {
  #Add scaling for simpleWriteRteMappingsRun mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$simpleWriteRteMappingsRun{$Mapping}})[0]; 
    my $inputExtType = getExtType((@{$simpleWriteRteMappingsRun{$Mapping}})[2]); 
    my $inputSlop = (@{$simpleWriteRteMappingsRun{$Mapping}})[1]; 
    my $inputBias = getBias((@{$simpleWriteRteMappingsRun{$Mapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$simpleWriteRteMappingsRun{$Mapping}})[4]; 
    my $outputExtType = getExtType((@{$simpleWriteRteMappingsRun{$Mapping}})[6]); 
    my $outputSlop = (@{$simpleWriteRteMappingsRun{$Mapping}})[5]; 
    my $outputBias = getBias((@{$simpleWriteRteMappingsRun{$Mapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  }
 foreach my $Mapping(keys %simpleReadRteMappingsRun) 
  {
  #Add scaling for simpleReadRteMappingsRun mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$simpleReadRteMappingsRun{$Mapping}})[0]; 
    my $inputExtType = getExtType((@{$simpleReadRteMappingsRun{$Mapping}})[2]); 
    my $inputSlop = (@{$simpleReadRteMappingsRun{$Mapping}})[1]; 
    my $inputBias = getBias((@{$simpleReadRteMappingsRun{$Mapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$simpleReadRteMappingsRun{$Mapping}})[4]; 
    my $outputExtType = getExtType((@{$simpleReadRteMappingsRun{$Mapping}})[6]); 
    my $outputSlop = (@{$simpleReadRteMappingsRun{$Mapping}})[5]; 
    my $outputBias = getBias((@{$simpleReadRteMappingsRun{$Mapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  }  
  
 foreach my $Mapping(keys %outputParameterMappingsRun) 
  {
  #Add scaling for outputParameterMappingsRun mappings
    #Input
    my $flavorattr1 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr2 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr3 = XML::LibXML::Element->new("flavorattr");
    
    #Output
    my $flavorattr4 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr5 = XML::LibXML::Element->new("flavorattr");
    my $flavorattr6 = XML::LibXML::Element->new("flavorattr");
    
    #Input
    my $input = (@{$outputParameterMappingsRun{$Mapping}})[0]; 
    my $inputExtType = getExtType((@{$outputParameterMappingsRun{$Mapping}})[2]); 
    my $inputSlop = (@{$outputParameterMappingsRun{$Mapping}})[1]; 
    my $inputBias = getBias((@{$outputParameterMappingsRun{$Mapping}})[12]);     
    $flavorattr1->setAttribute('decl'=>$input); 
    $flavorattr1->setAttribute('name'=>'external-type'); 
    $flavorattr1->setAttribute('value'=>$inputExtType);    
    $flavorattr2->setAttribute('decl'=>$input); 
    $flavorattr2->setAttribute('name'=>'slope'); 
    $flavorattr2->setAttribute('value'=>$inputSlop);
    $flavorattr3->setAttribute('decl'=>$input); 
    $flavorattr3->setAttribute('name'=>'bias'); 
    $flavorattr3->setAttribute('value'=>$inputBias);
    
    #Output
    my $output = (@{$outputParameterMappingsRun{$Mapping}})[4]; 
    my $outputExtType = getExtType((@{$outputParameterMappingsRun{$Mapping}})[6]); 
    my $outputSlop = (@{$outputParameterMappingsRun{$Mapping}})[5]; 
    my $outputBias = getBias((@{$outputParameterMappingsRun{$Mapping}})[13]);     
    $flavorattr4->setAttribute('decl'=>$output); 
    $flavorattr4->setAttribute('name'=>'external-type'); 
    $flavorattr4->setAttribute('value'=>$outputExtType);    
    $flavorattr5->setAttribute('decl'=>$output); 
    $flavorattr5->setAttribute('name'=>'slope'); 
    $flavorattr5->setAttribute('value'=>$outputSlop);
    $flavorattr6->setAttribute('decl'=>$output); 
    $flavorattr6->setAttribute('name'=>'bias'); 
    $flavorattr6->setAttribute('value'=>$outputBias);
    
    my @flavorScaling = $element->getElementsByTagName("flavor");   
    foreach my $minMax(@flavorScaling)
    {
      if($minMax->getAttribute("type") eq "Scaling")
      {
        #$minMax->addChild($flavorattr1); 
        #$minMax->addChild($flavorattr2);
        #$minMax->addChild($flavorattr3);  
        #$minMax->addChild($flavorattr4);
        #$minMax->addChild($flavorattr5);
        #$minMax->addChild($flavorattr6);        
      }
    }    
  }
}


sub AddInputOutput
{
  my ($element, $file) = @_; 
  foreach my $outputParMapping(keys %outputMappingsRun) 
  #Add InputOutput for Output Mapping
  {
    #Input
    my $inputTag = XML::LibXML::Element->new("input");    
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Input
    my $input = (@{$outputMappingsRun{$outputParMapping}})[0];     
    #Output
    my $output = (@{$outputMappingsRun{$outputParMapping}})[4];  
    
    $inputTag->setAttribute('name'=>$input);    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   
    #$signature[0]->addChild($inputTag); 
    #$signature[0]->addChild($outputTag);    
  }
  
   
  
    foreach my $inputMapping(keys %inputMappingsRun) 
  {
    #Add inputOutput for input mappings
    #Input
    my $inputTag = XML::LibXML::Element->new("input");    
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Input
    my $input = (@{$inputMappingsRun{$inputMapping}})[0];     
    #Output
    my $output = (@{$inputMappingsRun{$inputMapping}})[4];  
    
    $inputTag->setAttribute('name'=>$input);    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   
    #$signature[0]->addChild($inputTag); 
    #$signature[0]->addChild($outputTag);    
  }
  
 foreach my $writeRteMapping(keys %writeRteMappingsRun) 
  {
    #Add inputOutput for writeRteMappingsRun mappings
    #Input
    my $inputTag = XML::LibXML::Element->new("input");    
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Input
    my $input = (@{$writeRteMappingsRun{$writeRteMapping}})[0];     
    #Output
    my $output = (@{$writeRteMappingsRun{$writeRteMapping}})[4];  
    
    $inputTag->setAttribute('name'=>$input);    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   
    #$signature[0]->addChild($inputTag); 
    #$signature[0]->addChild($outputTag);    
  }

  foreach my $Mapping(keys %readRteMappingsRun) 
  #Add InputOutput for readRteMappingsRun Mapping
  {
    #Input
    my $inputTag = XML::LibXML::Element->new("input");    
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Input
    my $input = (@{$readRteMappingsRun{$Mapping}})[0];     
    #Output
    my $output = (@{$readRteMappingsRun{$Mapping}})[4];  
    
    $inputTag->setAttribute('name'=>$input);    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   
    #$signature[0]->addChild($inputTag); 
    #$signature[0]->addChild($outputTag);    
  }  
  
  foreach my $Mapping(keys %simpleWriteRteMappingsRun) 
  #Add InputOutput for simpleWriteRteMappingsRun Mapping
  {
    #Input
    my $inputTag = XML::LibXML::Element->new("input");    
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Input
    my $input = (@{$simpleWriteRteMappingsRun{$Mapping}})[0];     
    #Output
    my $output = (@{$simpleWriteRteMappingsRun{$Mapping}})[4];  
    
    $inputTag->setAttribute('name'=>$input);    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   
    #$signature[0]->addChild($inputTag); 
    #$signature[0]->addChild($outputTag);    
  } 
  foreach my $Mapping(keys %simpleReadRteMappingsRun) 
  #Add InputOutput for simpleReadRteMappingsRun Mapping
  {
    #Input
    my $inputTag = XML::LibXML::Element->new("input");    
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Input
    my $input = (@{$simpleReadRteMappingsRun{$Mapping}})[0];     
    #Output
    my $output = (@{$simpleReadRteMappingsRun{$Mapping}})[4];  
    
    $inputTag->setAttribute('name'=>$input);    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   
    #$signature[0]->addChild($inputTag); 
    #$signature[0]->addChild($outputTag);    
  } 

  foreach my $Mapping(keys %writeRteParameterMappingsRun) 
  #Add InputOutput for writeRteParameterMappingsRun Mapping
  {

    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
  
    #Output
    my $output = (@{$writeRteParameterMappingsRun{$Mapping}})[4];  
    
    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");
    #$signature[0]->addChild($outputTag);    
  } 
  
  foreach my $Mapping(keys %outputParameterMappingsRun) 
  #Add InputOutput for outputParameterMappingsRun Mapping
  {
   
    #Output
    my $outputTag = XML::LibXML::Element->new("output");    
    
    #Output
    my $output = (@{$outputParameterMappingsRun{$Mapping}})[4];  

    $outputTag->setAttribute('name'=>$output); 
    
    my @signature = $element->getElementsByTagName("signature");   

    #$signature[0]->addChild($outputTag);    
  }
}

sub AddInitTestCase
{
  my ($element, $file) = @_; 
	#Add InitTestCase for Output Mappings
	print OUTPUTFILE "INFO: Adding Init Test Cases for Output Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $outputMapping(keys %outputMappingsInit)   
  {
	  createInitTestCase($element, \%outputMappingsInit, $outputMapping);	  	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for writeRteMappings Mappings	
	print OUTPUTFILE "INFO: Adding Init Test Cases for WriteRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
	foreach my $writeRteMapping(keys %writeRteMappingsInit) 
  {
	  createInitTestCase($element, \%writeRteMappingsInit, $writeRteMapping);
  }
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for outputParameterMappingsInit Mapping
  print OUTPUTFILE "INFO: Adding Init Test Cases for Output Parameter Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $outputParMapping(keys %outputParameterMappingsInit)   
  {
	  createInitTestCaseParameter($element, \%outputParameterMappingsInit, $outputParMapping);    
  }	
	print OUTPUTFILE "-------------------------------------------------------------\n";
  
  
  #Add InitTestCase for Mapping Type 9
  print OUTPUTFILE "INFO: Adding Init Test Cases for Mapping Type 9:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $mappingType9(keys %MappingType9Init)   
  {
	  createInitTestCaseParameter($element, \%MappingType9Init, $mappingType9);    
  }	
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for writeRteParameterMappingsInit Mapping  
	print OUTPUTFILE "INFO: Adding Init Test Cases for WriteRte Parameter Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $writeRteParMapping(keys %writeRteParameterMappingsInit)   
  {
	  createInitTestCaseParameter($element, \%writeRteParameterMappingsInit, $writeRteParMapping); 	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n";
  
	#Add InitTestCase for input Mapping
	print OUTPUTFILE "INFO: Adding Init Test Cases for Input Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $inputMapping(keys %inputMappingsInit) 
  {
	  createInitTestCase($element, \%inputMappingsInit, $inputMapping);	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for readRteMappingsInit Mapping
  print OUTPUTFILE "INFO: Adding Init Test Cases for ReadRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";    
	foreach my $readRteMapping(keys %readRteMappingsInit) 
  {
	  createInitTestCase($element, \%readRteMappingsInit, $readRteMapping);	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for simpleWriteRteMappingsInit Mapping
	print OUTPUTFILE "INFO: Adding Init Test Cases for Simple WriteRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $simpleWriteRteMapping(keys %simpleWriteRteMappingsInit) 
  {
	  createInitTestCase($element, \%simpleWriteRteMappingsInit, $simpleWriteRteMapping);
	}
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for simpleReadRteMappings Mapping		
	print OUTPUTFILE "INFO: Adding Init Test Cases for Simple ReadRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $simpleReadRteMapping(keys %simpleReadRteMappingsInit) 
  {
	  createInitTestCase($element, \%simpleReadRteMappingsInit, $simpleReadRteMapping);		
	}
	print OUTPUTFILE "-------------------------------------------------------------\n";
	
	#Add InitTestCase for mappint type 4 Mapping		
	print OUTPUTFILE "INFO: Adding Init Test Cases for Mapping type 4:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $mappingtype4eMapping(keys %MappingType4Init) 
  {
	  createMapping4InitTestCase($element, \%MappingType4Init, $mappingtype4eMapping);		
	}
	print OUTPUTFILE "-------------------------------------------------------------\n";
}


sub AddRunTestCase
{
  my ($element, $file) = @_; 
	#Add Run TestCase for Output Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for Output Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
  foreach my $outputMapping(keys %outputMappingsRun) 
  {
	  createRunTestCase($element, \%outputMappingsRun, $outputMapping);	   
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 

	#Add RunTestCase for writeRteMappingsRun Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for WriteRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $writeRteMapping(keys %writeRteMappingsRun)   
  {   
	  createRunTestCase($element, \%writeRteMappingsRun, $writeRteMapping);	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
	
	#Add RunTestCase for outputParameterMappingsRun Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for Output Parameter Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $outputParMapping(keys %outputParameterMappingsRun) 
  {
	  createRunTestCaseParameter($element, \%outputParameterMappingsRun, $outputParMapping);	  	
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
  
	#Add InitTestCase for writeRteParameterMappingsRun Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for WriteRte Parameter Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $writeRteParMapping(keys %writeRteParameterMappingsRun)   
  {
	  createRunTestCaseParameter($element, \%writeRteParameterMappingsRun, $writeRteParMapping);	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
  
	#Add RunTestCase for Output Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for Input Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $inputMapping(keys %inputMappingsRun) 
  {
	  createRunTestCase($element, \%inputMappingsRun, $inputMapping);	 	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
	
	#Add RunTestCase for readRteMappingsRun Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for ReadRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
	foreach my $readRteMapping(keys %readRteMappingsRun) 
  {
	  createRunTestCase($element, \%readRteMappingsRun, $readRteMapping);	
  }  
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
  
	#Add RunTestCase for simpleWriteRteMappingsRun Mapping
	print OUTPUTFILE "INFO: Adding Run Test Cases for Simple WriteRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";
  foreach my $simpleWriteRte(keys %simpleWriteRteMappingsRun) 
  {
	  createRunTestCase($element, \%simpleWriteRteMappingsRun, $simpleWriteRte);	  
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
	
	print OUTPUTFILE "INFO: Adding Run Test Cases for Simple ReadRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $simpleReadRteMapping(keys %simpleReadRteMappingsRun) 
  {
	  createRunTestCase($element, \%simpleReadRteMappingsRun, $simpleReadRteMapping);
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
	
	#Add RunTestCase for Mapping type4 
	print OUTPUTFILE "INFO: Adding Run Test Cases for Simple ReadRte Mappings:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $mapping4RteMapping(keys %MappingType4Run) 
  {
	   createMapping4RunTestCase($element, \%MappingType4Run, $mapping4RteMapping);
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
	
	#Add RunTestCase for Mapping type4 
	print OUTPUTFILE "INFO: Adding Run Test Cases for Mapping type4:\n";
	print OUTPUTFILE "-------------------------------------------------------------\n";  
  foreach my $mapping9Mapping(keys %MappingType9Run ) 
  {
	   createRunTestCase($element, \%MappingType9Run , $mapping9Mapping);
  }
	print OUTPUTFILE "-------------------------------------------------------------\n"; 
	
}

sub getTptType
{
  my($docmiscType) = @_;   
  my $datatype="";
  if($docmiscType =~ m/Boolean/) { $datatype = "B_TRUE";} #B_TRUE
  elsif($docmiscType =~ m/UInt8/) { $datatype = "uint8"; }
  elsif($docmiscType =~ m/UInt16/) { $datatype = "uint16"; }
  elsif($docmiscType =~ m/UInt32/) { $datatype = "uint32"; }
  elsif($docmiscType =~ m/SInt8/) { $datatype = "int8"; }
  elsif($docmiscType =~ m/SInt16/) { $datatype = "int16"; }
  elsif($docmiscType =~ m/SInt32/) { $datatype = "int32"; }
  elsif($docmiscType =~ m/real32/) { $datatype = "float"; }
  else{print "[INFO]: Handle the Type: $docmiscType Manually \n"}  # Need to update for real types in next version
  return $datatype; 
}

sub getExtType
{
  my($docmiscType) = @_;   
  my $datatype="";
  if($docmiscType =~ m/Boolean/) { $datatype = "UINT8";}
  elsif($docmiscType =~ m/UInt8/) { $datatype = "UINT8"; }
  elsif($docmiscType =~ m/UInt16/) { $datatype = "UINT16"; }
  elsif($docmiscType =~ m/UInt32/) { $datatype = "UINT32"; }
  elsif($docmiscType =~ m/SInt8/) { $datatype = "INT8"; }
  elsif($docmiscType =~ m/SInt16/) { $datatype = "INT16"; }
  elsif($docmiscType =~ m/SInt32/) { $datatype = "INT32"; }
  elsif($docmiscType =~ m/real32/) { $datatype = "FLOAT"; }
  else{print "[INFO]: Handle the Type: $docmiscType Manually \n"}  # Need to update for real types in next version
  return $datatype; 
}

sub getBias
{
  my($offset) = @_;   
  my $bias="-0.0";
  if($offset eq '0') { $bias = "-0.0";}
  elsif($offset eq '0.0') { $bias = "-0.0";}   
  else{$bias = $offset;}
  return $bias; 
}

#===================================
# Common Function to Add Init Test Case
#===================================
sub createInitTestCase
{
  my($element, $mappingsHash, $mapping) = @_; 	
	
  #Description Text
  my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  
	my $input = (@{$mappingsHash->{$mapping}})[0]; 			         
  my $output = (@{$mappingsHash->{$mapping}})[4]; 			
  my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
  my $scaling = (@{$mappingsHash->{$mapping}})[1];	
  my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	
  my $inputMax = (@{$mappingsHash->{$mapping}})[9];
  my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
  my $outputMax = (@{$mappingsHash->{$mapping}})[11]; 
  my $inputType = getTptType((@{$mappingsHash->{$mapping}})[2]);
	my $mappingType = (@{$mappingsHash->{$mapping}})[15];
	my $ADDMappingTYpe = (@{$mappingsHash->{$mapping}})[16];		
	
	my @randomValue = calcIntermediateValues($input, $inputMin, $outputMin, $inputMax, $outputMax, $scaling, $outputscaling);	
  
  #Get New Min and Max Value   
  my $outputMinNew = calculateNewMin($inputMin, $outputMin);	
	my $outputMaxNew = calculateNewMax($inputMax, $outputMax);
	my @randomValueNew=();
	$randomValueNew[0] = calculateNewIntermediateValue($randomValue[0], $outputMin, $outputMax);
	$randomValueNew[1] = calculateNewIntermediateValue($randomValue[1], $outputMin, $outputMax);
	$randomValueNew[2] = calculateNewIntermediateValue($randomValue[2], $outputMin, $outputMax);
	$randomValueNew[3] = calculateNewIntermediateValue($randomValue[3], $outputMin, $outputMax);	
	
	
	if(($scaling eq '1.0') or ($scaling eq '1'))
	{
    $inputMin=~ s/\.\d+$//; 
    $inputMax=~ s/\.\d+$//;	
		$outputMinNew=~ s/\.\d+$//;
		$randomValue[0]=~ s/\.\d+$//;
		$randomValue[1]=~ s/\.\d+$//;
		$randomValue[2]=~ s/\.\d+$//;
		$randomValue[3]=~ s/\.\d+$//;
  }	   
	
	my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
  foreach my $state(@states)  
  {
    if($state->getAttribute("name") eq 'Init' && $inputType ne 'B_TRUE' && $mappingType != 9 )
    {
		  print OUTPUTFILE "INFO: Adding Init Test Case with Source --> $input\n";
			if($ADDMappingTYpe ne 'simple')
			{
			  print OUTPUTFILE "WARNING: Complex or factor/offset Mapping, Please re-check the Test Case for $input\n";
			}			
      my @scenarios = $state->getElementsByTagName('scenario_ts');    
      my @refNone = $state->getElementsByTagName('extension');
			addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);  
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMin);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMinNew,$outputscaling); 
      addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[0]);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $randomValue[0]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[0],$outputscaling);			
			addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[1]);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $randomValue[1]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[1],$outputscaling);            
			addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[2]);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $randomValue[2]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[2],$outputscaling);           
			addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[3]);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $randomValue[3]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[3],$outputscaling);            
			addWait($scenarios[0], $refNone[0]);
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMax);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMaxNew,$outputscaling);     
			addWait($scenarios[0], $refNone[0]);  
    }
		elsif($state->getAttribute("name") eq 'Init'  && $inputType eq 'B_TRUE' && $mappingType != 9)
    {
		  print OUTPUTFILE "INFO: Adding Init Test Case with Source --> $input\n";
      my @scenarios = $state->getElementsByTagName('scenario_ts');    
      my @refNone = $state->getElementsByTagName('extension');
			addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);  
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMin);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
			addCompare($scenarios[0], $refNone[0],$output, $outputMinNew);              
			addWait($scenarios[0], $refNone[0]);			
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMax);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
			addCompare($scenarios[0], $refNone[0],$output, $outputMaxNew);     
			addWait($scenarios[0], $refNone[0]); 
		}
		elsif($mappingType == 9)
		{
		  print OUTPUTFILE "WARNING: Mapping Type 9. Please add Manually for --> $input\n";
		}
  }      
}

#===================================
# Common Function to Add Init Test Case For Parameter
#===================================
sub createInitTestCaseParameter
{
  my($element, $mappingsHash, $mapping) = @_;   
  my $mappingType = (@{$mappingsHash->{$mapping}})[15];

  
  if($mappingType == 9){  
    my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  	           
    my $output = (@{$mappingsHash->{$mapping}})[4]; 			
    my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
    my $scaling = (@{$mappingsHash->{$mapping}})[1];	
    my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	    
    my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
    my $outputMax = (@{$mappingsHash->{$mapping}})[11];      
    my $ADDMappingTYpe = (@{$mappingsHash->{$mapping}})[16];
    
    my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
    foreach my $state(@states)  
    {
      if($state->getAttribute("name") eq 'Init')
      {
        print OUTPUTFILE "INFO: Adding Init Test Case with Target --> $output\n";
        if($ADDMappingTYpe ne 'simple')
        {
          print OUTPUTFILE "WARNING: Complex or factor/offset Mapping, Please re-check the Test Case for $output\n";
        }	
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]); 
        addWait($scenarios[0], $refNone[0]);
        addCompare($scenarios[0], $refNone[0],$output, $inputMin);	
        addWait($scenarios[0], $refNone[0]);
      }
      elsif($state->getAttribute("name") eq 'Init')
      {
        print OUTPUTFILE "INFO: Adding Init Test Case with Target --> $output\n";
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);          		
        addWait($scenarios[0], $refNone[0]);  
        addCompare($scenarios[0], $refNone[0],$output, $inputMin);		
        addWait($scenarios[0], $refNone[0]);       
      }      
    }  
  }
  else{   
  
    my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  
	  my $input = (@{$mappingsHash->{$mapping}})[0]; 			         
    my $output = (@{$mappingsHash->{$mapping}})[4]; 			
    my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
    my $scaling = (@{$mappingsHash->{$mapping}})[1];	
    my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	
    my $inputMax = (@{$mappingsHash->{$mapping}})[9];
    my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
    my $outputMax = (@{$mappingsHash->{$mapping}})[11];  
    my $inputType = getTptType((@{$mappingsHash->{$mapping}})[2]); 
    my $mappingType = (@{$mappingsHash->{$mapping}})[15];
    my $ADDMappingTYpe = (@{$mappingsHash->{$mapping}})[16];
  
    my @randomValue = calcIntermediateValues($input, $inputMin, $outputMin, $inputMax, $outputMax, $scaling, $outputscaling);	
    
    #Get New Min and Max Value
    my $outputMinNew = calculateNewMin($inputMin, $outputMin);
    my $outputMaxNew = calculateNewMax($inputMax, $outputMax); 
    my @randomValueNew=();
    $randomValueNew[0] = calculateNewIntermediateValue($randomValue[0], $outputMin, $outputMax);
    $randomValueNew[1] = calculateNewIntermediateValue($randomValue[1], $outputMin, $outputMax);
    $randomValueNew[2] = calculateNewIntermediateValue($randomValue[2], $outputMin, $outputMax);
    $randomValueNew[3] = calculateNewIntermediateValue($randomValue[3], $outputMin, $outputMax);

    if(($scaling eq '1.0') or ($scaling eq '1'))
    {
      $inputMin=~ s/\.\d+$//;   
      $inputMax=~ s/\.\d+$//;		  
      $outputMinNew=~ s/\.\d+$//;
      $randomValue[0]=~ s/\.\d+$//;
      $randomValue[1]=~ s/\.\d+$//;
      $randomValue[2]=~ s/\.\d+$//;
      $randomValue[3]=~ s/\.\d+$//;
    }		  
    
    my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
    foreach my $state(@states)  
    {
      if($state->getAttribute("name") eq 'Init' && $inputType ne 'B_TRUE' && $mappingType != 9)
      {
        print OUTPUTFILE "INFO: Adding Init Test Case with Source --> $input\n";
        if($ADDMappingTYpe ne 'simple')
        {
          print OUTPUTFILE "WARNING: Complex or factor/offset Mapping, Please re-check the Test Case for $input\n";
        }	
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);
        addSetParameter($scenarios[0], $refNone[0],$input, $inputMin);			
        addWait($scenarios[0], $refNone[0]);      
        addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
        addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMinNew,$outputscaling);	
        addWait($scenarios[0], $refNone[0]);
        addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[0]);			
        addWait($scenarios[0], $refNone[0]);
        addCompare($scenarios[0], $refNone[0],$input, $randomValue[0]);			
        addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[0],$outputscaling);			
        addWait($scenarios[0], $refNone[0]);
        addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[1]);	
        addWait($scenarios[0], $refNone[0]);
        addCompare($scenarios[0], $refNone[0],$input, $randomValue[1]);			
        addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[1],$outputscaling);  
        addWait($scenarios[0], $refNone[0]);
        addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[2]);	
        addWait($scenarios[0], $refNone[0]);
        addCompare($scenarios[0], $refNone[0],$input, $randomValue[2]);			
        addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[2],$outputscaling); 
        addWait($scenarios[0], $refNone[0]);			
        addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[3]);	
        addWait($scenarios[0], $refNone[0]);
        addCompare($scenarios[0], $refNone[0],$input, $randomValue[3]);			
        addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[3],$outputscaling); 
        addWait($scenarios[0], $refNone[0]);				
        addSetParameter($scenarios[0], $refNone[0],$input, $inputMax);			
        addWait($scenarios[0], $refNone[0]);      
        addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
        addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMaxNew,$outputscaling);			
        addWait($scenarios[0], $refNone[0]);    
      }
      elsif($state->getAttribute("name") eq 'Init'  && $inputType eq 'B_TRUE' && $mappingType != 9)
      {
        print OUTPUTFILE "INFO: Adding Init Test Case with Source --> $input\n";
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);  
        addSetParameter($scenarios[0], $refNone[0],$input, $inputMin);			
        addWait($scenarios[0], $refNone[0]);      
        addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
        addCompare($scenarios[0], $refNone[0],$output, $outputMinNew);			
        addWait($scenarios[0], $refNone[0]);			  
        addSetParameter($scenarios[0], $refNone[0],$input, $inputMax);			
        addWait($scenarios[0], $refNone[0]);      
        addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
        addCompare($scenarios[0], $refNone[0],$output, $outputMaxNew);			
        addWait($scenarios[0], $refNone[0]); 
      }
      elsif($mappingType == 9)
      {
        print OUTPUTFILE "WARNING: Mapping Type 9. Please add Manually for --> $input\n";
      }
    }
  }    
}

sub createMapping4InitTestCase
{
  my($element, $mappingsHash, $mapping) = @_;   
  

   my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  
	my $inputtemp = (@{$mappingsHash->{$mapping}})[0]; 	
  my $input = "DINH_stFId_".$inputtemp;
  my $output = (@{$mappingsHash->{$mapping}})[4]; 			
  my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
  my $scaling = (@{$mappingsHash->{$mapping}})[1];	
  my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	
  my $inputMax = (@{$mappingsHash->{$mapping}})[9];
  my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
  my $outputMax = (@{$mappingsHash->{$mapping}})[11]; 
	my $inputType = getTptType((@{$mappingsHash->{$mapping}})[2]);
	my $mappingType = (@{$mappingsHash->{$mapping}})[15];
	my $ADDMappingType = (@{$mappingsHash->{$mapping}})[16];
    
    my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
    foreach my $state(@states)  
    {
	if($state->getAttribute("name") eq 'Init')
      {
	    
        print OUTPUTFILE "INFO: Adding Init Test Case with Target --> $output\n";
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);   
		addSetChannel($scenarios[0], $refNone[0],$input, 0);		
        addWait($scenarios[0], $refNone[0]);  
        addCompare($scenarios[0], $refNone[0],$input, 0);	
		addCompare($scenarios[0], $refNone[0],$output, 0);		
        addWait($scenarios[0], $refNone[0]);  

		addSetChannel($scenarios[0], $refNone[0],$input, 32);		
        addWait($scenarios[0], $refNone[0]);  
        addCompare($scenarios[0], $refNone[0],$input, 32);	
        addCompare($scenarios[0], $refNone[0],$output, 1);		
        addWait($scenarios[0], $refNone[0]); 
}		
          
    }  
  
}


sub createRunTestCase
{
  my($element, $mappingsHash, $mapping) = @_; 
  my $mappingType = (@{$mappingsHash->{$mapping}})[15];

  
  if($mappingType == 9){  
    my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  	           
    my $output = (@{$mappingsHash->{$mapping}})[4]; 			
    my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
    my $scaling = (@{$mappingsHash->{$mapping}})[1];	
    my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	    
    my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
    my $outputMax = (@{$mappingsHash->{$mapping}})[11];      
    my $ADDMappingTYpe = (@{$mappingsHash->{$mapping}})[16];
    
    my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
    foreach my $state(@states)  
    {
      if($state->getAttribute("name") eq 'Run')
      {
        print OUTPUTFILE "INFO: Adding Run Test Case with Target --> $output\n";
        if($ADDMappingTYpe ne 'simple')
        {
          print OUTPUTFILE "WARNING: Complex or factor/offset Mapping, Please re-check the Test Case for $output\n";
        }	
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]); 
        addWait($scenarios[0], $refNone[0]);
        addCompare($scenarios[0], $refNone[0],$output, $inputMin);	
        addWait($scenarios[0], $refNone[0]);
      }
      elsif($state->getAttribute("name") eq 'Run')
      {
        print OUTPUTFILE "INFO: Adding Run Test Case with Target --> $output\n";
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);          		
        addWait($scenarios[0], $refNone[0]);  
        addCompare($scenarios[0], $refNone[0],$output, $inputMin);		
        addWait($scenarios[0], $refNone[0]);       
      }      
    }  
  }
  else{ 
  #Description Text
  my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  
	my $input = (@{$mappingsHash->{$mapping}})[0]; 			         
  my $output = (@{$mappingsHash->{$mapping}})[4]; 			
  my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
  my $scaling = (@{$mappingsHash->{$mapping}})[1];	
  my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	
  my $inputMax = (@{$mappingsHash->{$mapping}})[9];
  my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
  my $outputMax = (@{$mappingsHash->{$mapping}})[11]; 
	my $inputType = getTptType((@{$mappingsHash->{$mapping}})[2]);
	my $offsetIn = (@{$mappingsHash->{$mapping}})[12];
	my $offsetOut = (@{$mappingsHash->{$mapping}})[13];
	my $dataTypeIN = (@{$mappingsHash->{$mapping}})[2]; 
	my $dataTypeOUT = (@{$mappingsHash->{$mapping}})[6]; 
	my $mappingType = (@{$mappingsHash->{$mapping}})[15];
	my $ADDMappingType = (@{$mappingsHash->{$mapping}})[16];	

	

  #3intermediate Value Generation
	#my @randomValue;
	#$randomValue[1] = ((int(rand(($inputMax-$inputMin)/$scaling)))* $scaling)+$inputMin;
	#$randomValue[2] = $randomValue[1] + $scaling;
	#$randomValue[3] = $randomValue[2] + $scaling;  
	
	my @randomValue = calcIntermediateValues($input, $inputMin, $outputMin, $inputMax, $outputMax, $scaling, $outputscaling);	
  
	#Get New Min and Max Value
	my $outputMinNew = calculateNewMin($inputMin, $outputMin);	
	my $outputMaxNew = calculateNewMax($inputMax, $outputMax);
	my $outrangeMin = $outputMin - 2; #=========================
	my $outrangeMax = $outputMax + 2; #=========================
  	
  my @randomValueNew=();
	$randomValueNew[0] = calculateNewIntermediateValue($randomValue[0], $outputMin, $outputMax);
	$randomValueNew[1] = calculateNewIntermediateValue($randomValue[1], $outputMin, $outputMax);
	$randomValueNew[2] = calculateNewIntermediateValue($randomValue[2], $outputMin, $outputMax);
	$randomValueNew[3] = calculateNewIntermediateValue($randomValue[3], $outputMin, $outputMax);		
		
	
	if(($scaling eq '1.0') or ($scaling eq '1'))
	{
    $inputMin=~ s/\.\d+$//;  
    $inputMax=~ s/\.\d+$//;	
	$outrangeMin=~ s/\.\d+$//;  
    $outrangeMax=~ s/\.\d+$//;
	$offsetIn=~ s/\.\d+$//;
	$offsetOut=~ s/\.\d+$//;
	$dataTypeIN=~ s/\.\d+$//;
	$dataTypeOUT=~ s/\.\d+$//;
		$outputMinNew=~ s/\.\d+$//;
		$randomValue[0]=~ s/\.\d+$//;
		$randomValue[1]=~ s/\.\d+$//;
		$randomValue[2]=~ s/\.\d+$//;
		$randomValue[3]=~ s/\.\d+$//;
  }	
  
	my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
  foreach my $state(@states)  
  {
    if($state->getAttribute("name") eq 'Run' && $inputType ne 'B_TRUE' && $mappingType != 9)
    {
		  print OUTPUTFILE "INFO: Adding Run Test Case for with Source --> $input\n";
			if($ADDMappingType ne 'simple')
			{
			  print OUTPUTFILE "WARNING: Complex or factor/offset Mapping, Please re-check the Test Case for $input\n";
			}
      my @scenarios = $state->getElementsByTagName('scenario_ts');    
      my @refNone = $state->getElementsByTagName('extension');
			addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);
			#===================================   outrange min
		if($dataTypeIN ne '-' && $dataTypeOUT ne '-')
		{
			if($dataTypeIN ne $dataTypeOUT)
			{
				if($offsetIn ne '-' && $offsetOut ne '-'){
					if(abs(int($offsetIn)) > 272 && abs(int($offsetOut)) > 272 && abs(int($outputMin)) > 3000)
					{
						#nothing
					}
					else{
						if ($dataTypeIN =~ m/UInt8/ || $dataTypeIN =~ m/UInt16/ || $dataTypeIN =~ m/UInt32/){
						#nothing
						}
						else {
							if($dataTypeIN =~ m/SInt8/) { 
								if (int($outrangeMin) < -128){
									$outrangeMin = -128;
								}
							}
							elsif($dataTypeIN =~ m/SInt16/) {
								if (int($outrangeMin) < -32768){
									$outrangeMin = -32768;
								} 
							}
							elsif($dataTypeIN =~ m/SInt32/) { 
								if (int($outrangeMin) < -2147483648){
									 $outrangeMin = -2147483648; 
								}
							} 
							addSetChannel($scenarios[0], $refNone[0],$input, $outrangeMin);			
							addWait($scenarios[0], $refNone[0]);
							addCompare($scenarios[0], $refNone[0],$input, $outrangeMin);			
							addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMin,$outputscaling); 
							addWait($scenarios[0], $refNone[0]);
						}
					}
				}
				else{
					if ($dataTypeIN =~ m/UInt8/ || $dataTypeIN =~ m/UInt16/ || $dataTypeIN =~ m/UInt32/){
						#nothing
						}
						else {
							if($dataTypeIN =~ m/SInt8/) { 
								if (int($outrangeMin) < -128){
									$outrangeMin = -128;
								}
							}
							elsif($dataTypeIN =~ m/SInt16/) {
								if (int($outrangeMin) < -32768){
									$outrangeMin = -32768;
								} 
							}
							elsif($dataTypeIN =~ m/SInt32/) { 
								if (int($outrangeMin) < -2147483648){
									 $outrangeMin = -2147483648; 
								}
							} 
							addSetChannel($scenarios[0], $refNone[0],$input, $outrangeMin);			
							addWait($scenarios[0], $refNone[0]);
							addCompare($scenarios[0], $refNone[0],$input, $outrangeMin);			
							addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMin,$outputscaling); 
							addWait($scenarios[0], $refNone[0]);
						}
				}
			}
		}
			#=====================================================
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMin);
			addWait($scenarios[0], $refNone[0]);        
      addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMinNew,$outputscaling);		
      addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[0]);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $randomValue[0]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[0],$outputscaling);				
			addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[1]);	
			addWait($scenarios[0], $refNone[0]);
			addCompare($scenarios[0], $refNone[0],$input, $randomValue[1]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[1],$outputscaling);  
			addWait($scenarios[0], $refNone[0]);
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[2]);	
			addWait($scenarios[0], $refNone[0]);
			addCompare($scenarios[0], $refNone[0],$input, $randomValue[2]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[2],$outputscaling);
      addWait($scenarios[0], $refNone[0]);			
			addSetChannel($scenarios[0], $refNone[0],$input, $randomValue[3]);	
			addWait($scenarios[0], $refNone[0]);
			addCompare($scenarios[0], $refNone[0],$input, $randomValue[3]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[3],$outputscaling);  
			addWait($scenarios[0], $refNone[0]);
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMax);			
			addWait($scenarios[0], $refNone[0]);           
      addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMaxNew,$outputscaling);			
			addWait($scenarios[0], $refNone[0]);     
			#===================================outrange max
		if($dataTypeIN ne '-' && $dataTypeOUT ne '-')
		{
			if($dataTypeIN ne $dataTypeOUT)
			{
				if($offsetIn ne '-' && $offsetOut ne '-'){
					if(abs(int($offsetIn)) > 272 && abs(int($offsetOut)) > 272 && abs(int($outputMax)) > 3000)
					{
						#nothing
					}
					else{
						if($dataTypeIN =~ m/SInt8/) { 
							if (int($outrangeMax) > 127){
								$outrangeMax = 127;
							}
						}
						elsif($dataTypeIN =~ m/SInt16/) {
							if (int($outrangeMax) > 32767){
								$outrangeMax = 32767;
							} 
						}
						elsif($dataTypeIN =~ m/SInt32/) { 
							if (int($outrangeMax) > 2147483647){
								 $outrangeMax = 2147483647; 
							}
						} 
						elsif($dataTypeIN =~ m/UInt8/) { 
							if (int($outrangeMax) > 255){
								 $outrangeMax = 255; 
							}
						}
						elsif($dataTypeIN =~ m/UInt16/) { 
							if (int($outrangeMax) > 65535){
								 $outrangeMax = 65535; 
							}
						} 
						elsif($dataTypeIN =~ m/UInt32/) { 
							if (int($outrangeMax) > 4294967295){
								 $outrangeMax = 4294967295; 
							}
						}
						if ($outrangeMax > $outputMax) {
							addSetChannel($scenarios[0], $refNone[0],$input, $outrangeMax);			
							addWait($scenarios[0], $refNone[0]);
							addCompare($scenarios[0], $refNone[0],$input, $outrangeMax);			
							addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMax,$outputscaling); 
							addWait($scenarios[0], $refNone[0]);
						}
					}
				}
				else{
					if($dataTypeIN =~ m/SInt8/) { 
							if (int($outrangeMax) > 127){
								$outrangeMax = 127;
							}
						}
						elsif($dataTypeIN =~ m/SInt16/) {
							if (int($outrangeMax) > 32767){
								$outrangeMax = 32767;
							} 
						}
						elsif($dataTypeIN =~ m/SInt32/) { 
							if (int($outrangeMax) > 2147483647){
								 $outrangeMax = 2147483647; 
							}
						} 
						elsif($dataTypeIN =~ m/UInt8/) { 
							if (int($outrangeMax) > 255){
								 $outrangeMax = 255; 
							}
						}
						elsif($dataTypeIN =~ m/UInt16/) { 
							if (int($outrangeMax) > 65535){
								 $outrangeMax = 65535; 
							}
						} 
						elsif($dataTypeIN =~ m/UInt32/) { 
							if (int($outrangeMax) > 4294967295){
								 $outrangeMax = 4294967295; 
							}
						}
						if ($outrangeMax > $outputMax) {
							addSetChannel($scenarios[0], $refNone[0],$input, $outrangeMax);			
							addWait($scenarios[0], $refNone[0]);
							addCompare($scenarios[0], $refNone[0],$input, $outrangeMax);			
							addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMax,$outputscaling); 
							addWait($scenarios[0], $refNone[0]);
						}
				}
			}
		}
			#=====================================================				
    }
		elsif($state->getAttribute("name") eq 'Run'  && $inputType eq 'B_TRUE' && $mappingType != 9)
    {
		  print OUTPUTFILE "INFO: Adding Run Test Case for with Source --> $input\n";
      my @scenarios = $state->getElementsByTagName('scenario_ts');    
      my @refNone = $state->getElementsByTagName('extension');
			addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMin);
			addWait($scenarios[0], $refNone[0]);        
      addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
			addCompare($scenarios[0], $refNone[0],$output, $outputMinNew);			
			addWait($scenarios[0], $refNone[0]);			  
      addSetChannel($scenarios[0], $refNone[0],$input, $inputMax);			
			addWait($scenarios[0], $refNone[0]);           
      addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
			addCompare($scenarios[0], $refNone[0],$output, $outputMaxNew);			
			addWait($scenarios[0], $refNone[0]);
		}
		elsif($mappingType == 9)
		{
		  print OUTPUTFILE "WARNING: Mapping Type 9. Please add Manually for --> $input\n";
		}
		}
  }
}

sub createMapping4RunTestCase
{
  my($element, $mappingsHash, $mapping) = @_;   
  
   my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  
	my $inputtemp = (@{$mappingsHash->{$mapping}})[0]; 	
  my $input = "DINH_stFId_".$inputtemp;
  my $output = (@{$mappingsHash->{$mapping}})[4]; 			
  my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
  my $scaling = (@{$mappingsHash->{$mapping}})[1];	
  my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	
  my $inputMax = (@{$mappingsHash->{$mapping}})[9];
  my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
  my $outputMax = (@{$mappingsHash->{$mapping}})[11]; 
	my $inputType = getTptType((@{$mappingsHash->{$mapping}})[2]);
	my $mappingType = (@{$mappingsHash->{$mapping}})[15];
	my $ADDMappingType = (@{$mappingsHash->{$mapping}})[16];
    
    my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
    foreach my $state(@states)  
    {
	if($state->getAttribute("name") eq 'Run')
      {
        print OUTPUTFILE "INFO: Adding Run Test Case with Target --> $output\n";
        my @scenarios = $state->getElementsByTagName('scenario_ts');    
        my @refNone = $state->getElementsByTagName('extension');
        addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);   
		addSetChannel($scenarios[0], $refNone[0],$input, 0);		
        addWait($scenarios[0], $refNone[0]);  
        addCompare($scenarios[0], $refNone[0],$input, 0);	
		addCompare($scenarios[0], $refNone[0],$output, 0);		
        addWait($scenarios[0], $refNone[0]);  

		addSetChannel($scenarios[0], $refNone[0],$input, 32);		
        addWait($scenarios[0], $refNone[0]);  
        addCompare($scenarios[0], $refNone[0],$input, 32);	
        addCompare($scenarios[0], $refNone[0],$output, 1);		
        addWait($scenarios[0], $refNone[0]); 	
}		
          
    }  
  
}
#===================================
# Common Function to Add Run Test Case For Parameter
#===================================
sub createRunTestCaseParameter
{
  my($element, $mappingsHash, $mapping) = @_; 
	
  #Description Text
  my $descriptionText = (@{$mappingsHash->{$mapping}})[4];  
	my $input = (@{$mappingsHash->{$mapping}})[0]; 			         
  my $output = (@{$mappingsHash->{$mapping}})[4]; 			
  my $inputMin = (@{$mappingsHash->{$mapping}})[8]; 
  my $scaling = (@{$mappingsHash->{$mapping}})[1];
  my $outputscaling = (@{$mappingsHash->{$mapping}})[5];	
  my $inputMax = (@{$mappingsHash->{$mapping}})[9];
  my $outputMin = (@{$mappingsHash->{$mapping}})[10]; 
  my $outputMax = (@{$mappingsHash->{$mapping}})[11];
	my $inputType = getTptType((@{$mappingsHash->{$mapping}})[2]);
	my $mappingType = (@{$mappingsHash->{$mapping}})[15];
	my $ADDMappingType = (@{$mappingsHash->{$mapping}})[16];	
	

  #3intermediate Value Generation
	#my @randomValue;
	#$randomValue[1] = ((int(rand(($inputMax-$inputMin)/$scaling)))* $scaling)+$inputMin;
	#$randomValue[2] = $randomValue[1] + $scaling;
	#$randomValue[3] = $randomValue[2] + $scaling; 	
	
	my @randomValue = calcIntermediateValues($input, $inputMin, $outputMin, $inputMax, $outputMax, $scaling, $outputscaling);	
  
  #Get New Min and Max Value 
  my $outputMinNew = calculateNewMin($inputMin, $outputMin); 	     
  my $outputMaxNew = calculateNewMax($inputMax, $outputMax);
  my @randomValueNew=();
	$randomValueNew[0] = calculateNewIntermediateValue($randomValue[0], $outputMin, $outputMax);
	$randomValueNew[1] = calculateNewIntermediateValue($randomValue[1], $outputMin, $outputMax);
	$randomValueNew[2] = calculateNewIntermediateValue($randomValue[2], $outputMin, $outputMax);
	$randomValueNew[3] = calculateNewIntermediateValue($randomValue[3], $outputMin, $outputMax);
	
	if(($scaling eq '1.0') or ($scaling eq '1'))
	{
    $inputMin=~ s/\.\d+$//;    
    $inputMax=~ s/\.\d+$//;		
		$outputMinNew=~ s/\.\d+$//;
		$randomValue[0]=~ s/\.\d+$//;
		$randomValue[1]=~ s/\.\d+$//;
		$randomValue[2]=~ s/\.\d+$//;
		$randomValue[3]=~ s/\.\d+$//;
  }	      	 
	
	my @states = ($element->getElementsByTagName("body"))[0]->getElementsByTagName('state'); 
  foreach my $state(@states)  
  {
    if($state->getAttribute("name") eq 'Run' && $inputType ne 'B_TRUE' && $mappingType != 9)
    {
		  print OUTPUTFILE "INFO: Adding Run Test Case with Source --> $input\n";
			if($ADDMappingType ne 'simple')
			{
			  print OUTPUTFILE "WARNING: Complex or factor/offset Mapping, Please re-check the Test Case for $input\n";
			}
      my @scenarios = $state->getElementsByTagName('scenario_ts');    
      my @refNone = $state->getElementsByTagName('extension');
			addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);
      addSetParameter($scenarios[0], $refNone[0],$input, $inputMin);			
			addWait($scenarios[0], $refNone[0]);        
      addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMinNew,$outputscaling);
			addWait($scenarios[0], $refNone[0]);
			addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[0]);			
			addWait($scenarios[0], $refNone[0]);
      addCompare($scenarios[0], $refNone[0],$input, $randomValue[0]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[0],$outputscaling);	
			addWait($scenarios[0], $refNone[0]);
			addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[1]);	
			addWait($scenarios[0], $refNone[0]);
			addCompare($scenarios[0], $refNone[0],$input, $randomValue[1]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[1],$outputscaling); 
      addWait($scenarios[0], $refNone[0]);			
			addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[2]);	
			addWait($scenarios[0], $refNone[0]);
			addCompare($scenarios[0], $refNone[0],$input, $randomValue[2]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[2],$outputscaling);  
			addWait($scenarios[0], $refNone[0]);
			addSetParameter($scenarios[0], $refNone[0],$input, $randomValue[3]);	
			addWait($scenarios[0], $refNone[0]);
			addCompare($scenarios[0], $refNone[0],$input, $randomValue[3]);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $randomValueNew[3],$outputscaling);  
			addWait($scenarios[0], $refNone[0]);
			addSetParameter($scenarios[0], $refNone[0],$input, $inputMax);			
			addWait($scenarios[0], $refNone[0]);       
			addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
			addCompareTolerance($scenarios[0], $refNone[0],$output, $outputMaxNew,$outputscaling);			
			addWait($scenarios[0], $refNone[0]);         
    }
		elsif($state->getAttribute("name") eq 'Run'  && $inputType eq 'B_TRUE' && $mappingType != 9)
    {
		  print OUTPUTFILE "INFO: Adding Run Test Case with Source --> $input\n";
      my @scenarios = $state->getElementsByTagName('scenario_ts');    
      my @refNone = $state->getElementsByTagName('extension');
			addDocumentaion($scenarios[0],$descriptionText, $refNone[0]);
      addSetParameter($scenarios[0], $refNone[0],$input, $inputMin);			
			addWait($scenarios[0], $refNone[0]);        
      addCompare($scenarios[0], $refNone[0],$input, $inputMin);			
			addCompare($scenarios[0], $refNone[0],$output, $outputMinNew);
			addWait($scenarios[0], $refNone[0]);			  
      addSetParameter($scenarios[0], $refNone[0],$input, $inputMax);			
			addWait($scenarios[0], $refNone[0]);       
      addCompare($scenarios[0], $refNone[0],$input, $inputMax);			
			addCompare($scenarios[0], $refNone[0],$output, $outputMaxNew);			
			addWait($scenarios[0], $refNone[0]);
		}
		elsif($mappingType == 9)
		{
		  print OUTPUTFILE "WARNING: Mapping Type 9. Please add Manually for --> $input\n";
		}
  }      
}

sub addDocumentaion
{
  my($parent, $description, $refNode) = @_; 	
	my $ts_doc = XML::LibXML::Element->new("ts_doc");
	$ts_doc->setAttribute('description'=>$description);
	$parent->insertBefore($ts_doc, $refNode);	
}

sub addWait
{
  my($parent, $refNode) = @_; 		
	my $ts_wait = XML::LibXML::Element->new("ts_wait");
	$ts_wait->setAttribute('time'=>'1s');	
	$parent->insertBefore($ts_wait, $refNode);	
}

sub addSetChannel
{
  my($parent, $refNode,$input,$inputMin) = @_; 	
  my $ts_setchannel = XML::LibXML::Element->new("ts_setchannel"); 
  $ts_setchannel->setAttribute('channel'=>$input);  
  $ts_setchannel->setAttribute('source'=>$inputMin); 		
	$parent->insertBefore($ts_setchannel, $refNode);	
}

sub addSetParameter
{
  my($parent, $refNode,$input,$inputMin) = @_; 	
  
  my $ts_setParameter = XML::LibXML::Element->new("ts_setparam"); 
  $ts_setParameter->setAttribute('channel'=>$input);  
  $ts_setParameter->setAttribute('source'=>$inputMin); 		
	$parent->insertBefore($ts_setParameter, $refNode);	
}

sub addCompare
{
  my($parent, $refNode,$input,$inputMin) = @_;
	my $ts_compare = XML::LibXML::Element->new("ts_compare");
	$ts_compare->setAttribute('actions'=>'Equal'); 
  $ts_compare->setAttribute('channel'=>$input);    
  $ts_compare->setAttribute('source'=>$inputMin); 
  $ts_compare->setAttribute('tolerance'=>'0');
  $ts_compare->setAttribute('type'=>'once'); 
	$parent->insertBefore($ts_compare, $refNode);
}

sub addCompareTolerance
{
  my($parent, $refNode,$input,$inputMin, $caling) = @_;
	my $ts_compare = XML::LibXML::Element->new("ts_compare");
	$ts_compare->setAttribute('actions'=>'Equal'); 
  $ts_compare->setAttribute('channel'=>$input);    
  $ts_compare->setAttribute('source'=>$inputMin); 
  $ts_compare->setAttribute('tolerance'=>$caling);
  $ts_compare->setAttribute('type'=>'once'); 
	$parent->insertBefore($ts_compare, $refNode);
}

sub calculateNewMin
{
  my($inputMin, $outputMin) = @_;
	my $outputMinNew = $inputMin;
  if( $outputMin > $inputMin)
	{
	  $outputMinNew = $outputMin;
	}	
	return $outputMinNew; 
}

sub calculateNewMax
{
  my($inputMax, $outputMax) = @_;
	my $outputMaxNew = $inputMax;
  if( $outputMax <  $inputMax)
	{
	  $outputMaxNew = $outputMax;
	}	
	return $outputMaxNew;
}



sub calcIntermediateValues
{
  my @intermediateValues = (); 
  my ($input, $inputMin, $outputMin, $inputMax, $outputMax, $scaling, $outputscaling) = @_; 
	if($inputMin >= 0)
	{
	  my $internalInputMax = $inputMax/$scaling;
		my $oneThirdOfInputInt = int($internalInputMax/3);
		my $oneTwoThirdOfInputInt = int(($internalInputMax*2)/3);				
		my $oneThirdOfInputPhys = $oneThirdOfInputInt*$scaling;
		my $TwoThirdOfInputPhys = $oneTwoThirdOfInputInt*$scaling;	
		my $oneThirdOfInputPhysPlusOne = $oneThirdOfInputPhys+$scaling;
		my $TwoThirdOfInputPhysPlusOne = $TwoThirdOfInputPhys+$scaling;		
		$intermediateValues[0]=$oneThirdOfInputPhys;
		$intermediateValues[1]=$oneThirdOfInputPhysPlusOne;
		$intermediateValues[2]=$TwoThirdOfInputPhys;
		$intermediateValues[3]=$TwoThirdOfInputPhysPlusOne;
	}
	else
	{
	  #my $absinternalMin = abs($inputMin);
	  my $internalInputMin = $inputMin/$scaling;
		my $internalInputMax = $inputMax/$scaling;
		my $halfOfInputMinInt = int($internalInputMin/2);
		my $halfOfInputMaxInt = int($internalInputMax/2);
		my $halfOfInputMinPhys = $halfOfInputMinInt*$scaling;
		my $halfOfInputMaxPhys = $halfOfInputMaxInt*$scaling;
		my $halfOfInputMinPhysPlusOne = $halfOfInputMinPhys+$scaling;
		my $halfOfInputMaxPhysPlusOne = $halfOfInputMaxPhys+$scaling;		
		$intermediateValues[0]=$halfOfInputMinPhys;
		$intermediateValues[1]=$halfOfInputMinPhysPlusOne;
		$intermediateValues[2]=$halfOfInputMaxPhys;
		$intermediateValues[3]=$halfOfInputMaxPhysPlusOne;
	}
	return @intermediateValues;
}

sub calculateNewIntermediateValue
{
  my($randomValue, $outputMin, $outputMax) = @_;
	my $newRandValue=$randomValue;
	if( $randomValue <  $outputMin)
	{
	  $newRandValue = $outputMin;
	}	
	elsif($randomValue > $outputMax)
	{
	  $newRandValue = $outputMax;
	}
	return $newRandValue;
}




#===================================
# Functions
#===================================
sub uniq{
	my %temp_hash = map { $_, 0 } @_;
	return keys %temp_hash;
}
