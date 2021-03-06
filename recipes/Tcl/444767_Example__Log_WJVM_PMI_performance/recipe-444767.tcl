# 
# Get JVM PMI info for server. 
# NB: server must be running and PMI must be switched on.
#
####################################################################
# Patrick Finnegan 11/11/2005.  V1. 
####################################################################

####################################################################
# Get Cloudscape connection.
####################################################################
proc dbconnect { databaseName } {

   puts "\n**********"
   puts "dbconnect"
   puts "**********\n"

   global env 
   global null

   foreach x [ lindex [ array get env TCL_CLASSPATH ] 1 ] {

       puts [ format "%-5s %-50s" " " $x ] 

   }

   # import required classes 
   java::import java.sql.Connection
   java::import java.sql.DriverManager
   java::import java.sql.ResultSet
   java::import java.sql.SQLWarning
   java::import java.sql.Statement
   java::import java.sql.ResultSetMetaData 
   java::import org.apache.derby.jdbc.EmbeddedDriver

   puts "imported classes are:\n"
   
   foreach i [java::import] {
       
      puts [ format "%-5s %-50s" " " $i ] 

   }
       
   # load db2 driver .
   java::call Class forName org.apache.derby.jdbc.EmbeddedDriver

   append url jdbc:derby:$databaseName

   puts "\n connection URL is:  $url\n"   

   java::try {
       
       set ConnectionI [ java::call DriverManager getConnection $url ] 

   } catch {SQLException SQLExceptionI } {

     catchSqlException $SQLExceptionI 
	 
   } catch {TclException e } {
       puts "TCl Exception to prepare statement $e"
       return -code error
   }

   puts "transaction isolation level is [ $ConnectionI getTransactionIsolation ] \n"

   java::lock $ConnectionI 

   return $ConnectionI 

}
####################################################################
# proc - get JVM details 
####################################################################
proc getJVMInfo { nodeName serverName ConnectionI } {

   global AdminConfig 
   global AdminControl
   global null
   global Help

   puts "\n**********"
   puts "getJVMInfo"
   puts "**********\n"

   #puts "\nget the performance mbean for the server - should be just one.\n"

   append queryString "WebSphere:*,node="
   append queryString $nodeName
   append queryString ",process="
   append queryString $serverName
   append queryString ",type=Perf"

   #puts "\n query string is: $queryString \n"

   set perfMbean [ $AdminControl queryNames $queryString ]

   if { $perfMbean == $null || [ string length $perfMbean] == 0 } {
       
       puts "\n $serverName is not running or PMI is not enabled for $serverName. \n"

       return -code error

   } else {

       set donothing true 

   }

   #puts "\nget the JVM Bean.\n"

   unset queryString 

   append queryString "WebSphere:*,node="
   append queryString $nodeName
   append queryString ",process="
   append queryString $serverName
   append queryString ",type=JVM"

   #puts "\n query string is: $queryString \n"

   set jvmMbean [ $AdminControl queryNames $queryString ]

   if { $jvmMbean == $null || [ string length $jvmMbean] == 0 } {
       
       puts "\n $serverName jvm is not running \n"

       return -code error

   } else {

       set donothing true 

   }

   set jvmMbeanO [ $AdminControl makeObjectName $jvmMbean ]

   set boolean [ java::new Boolean recursive ]
   # NB: brackets around array object. 
   set parramsArray    [ java::new {Object[]} {2} [ list $jvmMbeanO $boolean ] ]
   set signaturesArray [ java::new {String[]} {2} [ list javax.management.ObjectName java.lang.Boolean ] ]

   set perfMbeanO [ $AdminControl makeObjectName $perfMbean ]

   #get the stats list from the performance bean
   set jvmInfo [ $AdminControl invoke_jmx $perfMbeanO "getStatsString" $parramsArray $signaturesArray   ] 

   set jvmInfoString [ $jvmInfo toString ] 

   #get PMI data sub list.
   set e4        [ lindex $jvmInfoString 3 ]  
   set dataList  [ lindex $e4 1 ]  
   set dataListL [ llength $dataList ]  

   # sort in id order
   set dataList [ lsort -dictionary -index 0 $dataList ] 

   set topParms [ lindex $dataList 0 ]  

   set width 60

   set descriptorIndex [ lsearch -glob $topParms {*Descriptor*} ]
   set descriptor      [ lindex $topParms $descriptorIndex ]
   set x1 "[ lindex [ lindex [ lindex $descriptor 1 ] 0 ] 0 ]"
   set x2 "[ lindex [ lindex [ lindex $descriptor 1 ] 0 ] 1 ]"
   puts    [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2
      
   set x1 "[ lindex [ lindex [ lindex $descriptor 1 ] 1 ] 0 ]"
   set x2 "[ lindex [ lindex [ lindex $descriptor 1 ] 1 ] 1 ]"
   puts    [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2

   set timeIndex [ lsearch -glob $topParms {*Time*} ]
   set time      [ lindex $topParms $timeIndex ]
   set x1        [ lindex [ lindex $topParms $timeIndex ] 0 ]
   set x2        [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
   puts          [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2

   set valueIndex [ lsearch -glob $topParms {*Value*} ]
   set value      [ lindex $topParms $valueIndex ]
   set x1         [ lindex [ lindex $value 1 ] 0 ]
   set x2         [ lindex [ lindex $value 1 ] 1 ]
   puts           [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2

   set x1         [ lindex [ lindex $value 2 ] 0 ]
   set x2         [ lindex [ lindex $value 2 ] 1 ]
   puts           [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2

   set x1         [ lindex [ lindex $value 3 ] 0 ]
   set x2         [ lindex [ lindex $value 3 ] 1 ]
   puts           [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2

   set x1         [ lindex [ lindex $value 4 ] 0 ]
   set x2         [ lindex [ lindex $value 4 ] 1 ]
   puts           [ format "%-${width}s %s"  $x1 $x2 ]

   lappend valuesList $x2
   
   set x 1 

   while { $x < $dataListL } {

      set e                [ lindex $dataList $x ]

      set idIndex          [ lsearch -glob $e {*Id*} ]
      set id               [ lindex $e $idIndex ]

      set pmiDataInfoIndex [ lsearch -glob $e {*PmiDataInfo*} ]
      set pmiDataInfo      [ lindex $e $pmiDataInfoIndex ]

      set nl               [ eval concat [ join $e ] ]
      set commentIndex     [ lsearch -glob $nl {*Comment*} ]
      set comment          [ lindex [ lindex $nl $commentIndex ] 1 ]
      
      set valueIndex       [ lsearch -glob $e {*Value*} ]
      set value            [ lindex [ lindex [ lindex $e $valueIndex ] 1 ] 1 ]

      puts [ format "%-${width}s %s"  $comment $value ]

      lappend valuesList $value

      incr x 

   }

   # write data to DB2. 
   
   writeData $ConnectionI $valuesList  

   unset valuesList 
}
####################################################################
# proc - write data to database. 
####################################################################
proc writeData { ConnectionI valuesList } {

   global AdminConfig 
   global AdminControl
   global null

   puts "\n**********"
   puts "writeData"
   puts "**********\n"

   set opt1 [java::field ResultSet TYPE_SCROLL_INSENSITIVE]
   set opt2 [java::field ResultSet CONCUR_READ_ONLY ]

   set statement "insert into prod.wasperformjvm values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"

   java::try {
       
       set StatementI [ $ConnectionI prepareStatement $statement ]

   } catch {SQLException SQLExceptionI } {

     catchSqlException $SQLExceptionI 
	 
   } catch {TclException e } {
       puts "TCl Exception to prepare statement $e"
       return -code error
   }

   set x 1

   foreach i $valuesList {

      $StatementI setString $x $i 

      incr x

   }

   #puts "execute sqlQuery"

   java::try {
       
       $StatementI executeUpdate   

   } catch {SQLException SQLExceptionI } {

     catchSqlException $SQLExceptionI 
	 
   } catch {TclException e } {
       puts "TCl Exception to prepare statement $e"
       return -code error
   }

}
####################################################################
# proc - sqlException. 
####################################################################
proc catchSqlException { SQLExceptionI } {

   global AdminConfig 
   global AdminControl
   global Help
   global null

   puts "\n**********"
   puts "catchSqlException"
   puts "**********\n"

   puts "\n*** Exception to prepare statement\n"

   while { [ $SQLExceptionI getNextException ] != $null } {

      set sqlCode       [ $SQLExceptionI toString         ]
      set sqlMessage    [ $SQLExceptionI getMessage       ]
      set errorCode     [ $SQLExceptionI getErrorCode     ] 
      set sqlState      [ $SQLExceptionI getSQLState      ] 
      set nextException [ $SQLExceptionI getNextException ]

      if { $nextException != $null } {
      
         set nextException [ $nextException toString ]

      } else {

         set nextException $null
         
      }

      if { $sqlCode       != $null } { puts "sql code is:       \t$sqlCode" }
      if { $sqlMessage    != $null } { puts "sql message is:    \t$sqlMessage " }
      if { $errorCode     != $null } { puts "error code is:     \t$errorCode" }
      if { $nextException != $null } { puts "next exception is: \t$nextException" }
      if { $sqlState      != $null } { puts "sql state is:      \t$sqlState" }

      return -code error

   }

}
####################################################################
# Main Control.
####################################################################

puts "\n argc = $argc \n"

if {$argc < 1} {
        return -code error "error - no arguments supplied.  Supply server name"
        puts "no arguments"
}

# Assume one cell, one deployment manager node and one application node. 

set cellId [ lindex [ $AdminConfig list Cell ] 0 ]
set nodes  [ $AdminConfig list Node ]

# delete the manager node from the list.

set manIndex   [ lsearch -glob $nodes *Manager* ]
set nodeId     [ lindex [ lreplace $nodes $manIndex $manIndex ] 0 ]

# get name attribute for cell and application node

set cellName [ $AdminConfig showAttribute $cellId name ]
set nodeName [ $AdminConfig showAttribute $nodeId name ]

set serverName [ lindex $argv 0 ]

set null [ java::null ]
global null

set databaseName C:/DERBYDatabases/Test1

if { [ catch { dbconnect $databaseName } r ] == 0 } {

   while {1} { 

     after 30000
     getJVMInfo $nodeName $serverName $r

   }

   $r close

} else {

    puts $r 
    exit 1   

}
