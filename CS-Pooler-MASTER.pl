#!/usr/bin/perl

use warnings;
use strict;

binmode(STDOUT, ":utf8");

### DO NOT INCLUDE
use ColdStartLib;

### DO INCLUDE
##################################################################################### 
# This program generates the pools for a particular query in a given batch. 
#
# Author: Shahzad Rajput
# Please send questions or comments to shahzad.rajput "at" gmail "dot" com
#
# For usage, run with no arguments
##################################################################################### 

my $version = "1.3";

# Filehandles for program and error output
my $program_output = *STDOUT{IO};
my $error_output = *STDERR{IO};


### DO NOT INCLUDE
##################################################################################### 
# Library inclusions
##################################################################################### 
### DO INCLUDE
### DO INCLUDE Utils                  ColdStartLib.pm
### DO INCLUDE Patterns               ColdStartLib.pm
### DO INCLUDE Logger                 ColdStartLib.pm
### DO INCLUDE Provenance             ColdStartLib.pm
### DO INCLUDE Predicates             ColdStartLib.pm
### DO INCLUDE Query                  ColdStartLib.pm
### DO INCLUDE QuerySet               ColdStartLib.pm
### DO INCLUDE EvaluationQueryOutput  ColdStartLib.pm
### DO INCLUDE Switches               ColdStartLib.pm

### DO NOT INCLUDE
# Hush up perl worrywart module
my $pattern = $main::comment_pattern;

### DO INCLUDE
##################################################################################### 
# Runtime switches and main program
##################################################################################### 

# Handle run-time switches
my $switches = SwitchProcessor->new($0, "Create pools for assessment. This script is the main script to be called for pooling.",
				    "");
$switches->addHelpSwitch("help", "Show help");
$switches->addHelpSwitch("h", undef);
$switches->addVarSwitch('hop', "Spefify the hop number for which the pool is being generated. Hop 0 is the same as round 1, similarly hop 1 is round 2.");
$switches->put('hop', '0');
$switches->addVarSwitch('batches_dir', "Spefify the directory containing batches.");
$switches->put('batches_dir', 'batches');
$switches->addVarSwitch('depth', "Specify the maximum depth for the pooled runs. This could be an integer value constant across slots or could be a file containing different slot depths written as slot and depth pair separated by space, one pair per line.");
$switches->addVarSwitch('epsilon', "Epsilon used for depth pooling where depth varies per slot");
$switches->addVarSwitch('error_file', "Specify a file to which error output should be redirected");
$switches->put('error_file', "STDERR");
$switches->addVarSwitch('verbosity', "Specify a verbosity level. 0=>OFF 1=>ON");
$switches->put('verbosity', '0');
$switches->addConstantSwitch('combine', 'true', "Combine assessments from all hops (levels) of a given batch and query. The location of the output file is displayed after the action is completed.");
$switches->addImmediateSwitch('version', sub { print "$0 version $version\n"; exit 0; }, "Print version number and exit");
$switches->addParam("batchid", "required", "The ID of the batch to which the query to be pooled belongs to.");
$switches->addParam("queryid", "required", "The ID of the query to be pooled.");

$switches->process(@ARGV);

my $hop = $switches->get("hop");
my $batches_dir = $switches->get("batches_dir");
my $batchid = $switches->get("batchid");
my $queryid = $switches->get("queryid");
my $depth = $switches->get("depth");
my $epsilon = $switches->get("epsilon");
my $verbosity = $switches->get("verbosity");

my $combine = $switches->get("combine");

# Check if the script is a MASTER script, in that case MASTER of all the dependent scripts are used.
my $master = "";
$master = "-MASTER" if($0=~/MASTER/);

my $cmd;

if( $combine ){
	$cmd  = "cat $batches_dir/$batchid/$queryid/*.csldc.assessed ";
	$cmd .= "$batches_dir/$batchid/$queryid/*/*.csldc.assessed ";
	$cmd .= "| sort > $batches_dir/$batchid/$queryid/pool.csldc.assessed";
	
	print "--running command: $cmd\n" if($verbosity);
	system($cmd);
	
	print "Combined assessment file is stored at: $batches_dir/$batchid/$queryid/pool.csldc.assessed\n";
}
elsif($hop == 0) {
	$cmd  = "perl CS-Pool$master.pl ";
	$cmd .= "-depth $depth " if(defined $depth);
	$cmd .= "-epsilon $epsilon " if(defined $depth && -e $depth && defined $epsilon);
	$cmd .= "-output_file $batches_dir/$batchid/$queryid/hop0_pool.csldc ";
	$cmd .= "-error_file $batches_dir/$batchid/$queryid/hop0_pool.errlog ";
	$cmd .= "$batches_dir/$batchid/$queryid/tac_kbp_2015_english_cold_start_slot_filling_evaluation_queries_v2.xml ";
	$cmd .= "$batches_dir/$batchid/$queryid/queries.index "; 
	$cmd .= "$batches_dir/$batchid/$queryid/runs/";
	
	print "--running command: $cmd\n" if($verbosity);
	system($cmd);	
}
elsif($hop==1) {
	
	$cmd  = "perl CS-ExpandAssessments$master.pl ";
	$cmd .= "-output_file $batches_dir/$batchid/$queryid/hop0_pool.cssf.assessed ";
	$cmd .= "-error_file $batches_dir/$batchid/$queryid/hop1_expandassessments.errlog ";
	$cmd .= "-hop1_query_file $batches_dir/$batchid/$queryid/hop1_queries.xml ";
	$cmd .= "$batches_dir/$batchid/$queryid/tac_kbp_2015_english_cold_start_evaluation_queries_v2.xml ";
	$cmd .= "$batches_dir/$batchid/$queryid/tac_kbp_2015_english_cold_start_slot_filling_evaluation_queries_v2.xml ";
	$cmd .= "$batches_dir/$batchid/$queryid/hop0_pool.csldc.assessed ";
	$cmd .= "$batches_dir/$batchid/$queryid/queries.index";
	
	print "--running command: $cmd\n\n" if($verbosity);
	system($cmd);
	
	$cmd = "perl CS-Pool$master.pl ";
	$cmd .= "-output_dir $batches_dir/$batchid/$queryid/ ";
	$cmd .= "-depth $depth " if(defined $depth);	
	$cmd .= "-epsilon $epsilon " if(defined $depth && -e $depth && defined $epsilon);
	$cmd .= "-error_file $batches_dir/$batchid/$queryid/hop1_pool.errlog ";
	$cmd .= "-hop0_assessment_file $batches_dir/$batchid/$queryid/hop0_pool.cssf.assessed ";
	$cmd .= "$batches_dir/$batchid/$queryid/tac_kbp_2015_english_cold_start_slot_filling_evaluation_queries_v2.xml ";
	$cmd .= "$batches_dir/$batchid/$queryid/queries.index ";
	$cmd .= "$batches_dir/$batchid/$queryid/runs/";	

	print "--running command: $cmd\n\n" if($verbosity);
	system($cmd);
}

################################################################################
# Revision History
################################################################################

# 1.0 - Initial version
# 1.1 - Run off of MASTER with MASTER scripts, if necessary
# 1.2 - Queries file's version 2 being used now
# 1.3 - Support added for pooling upto a certain depth, and depth/per slot with epsilon.


1;