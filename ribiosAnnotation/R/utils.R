#' @importFrom DBI dbConnect dbExistsTable dbSendQuery dbHasCompleted  fetch dbClearResult dbDisconnect
#' @importFrom ribiosUtils matchColumn putColsFirst

##--------------------##
## constants
##--------------------##
## bi@bia
ORACLE.BIA.USER <- "bi"
ORACLE.BIA.PWD <- "bi"
## bi2@bia
ORACLE.BIA2.USER <- "bi2"
ORACLE.BIA2.PWD <- "wolf"
## biread@bia
ORACLE.BIARO.USER <- "biread"
ORACLE.BIARO.PWD <- "biread"
## red
ORACLE.RED.USER <- "red"
ORACLE.RED.PWD <- "red"
## genome
ORACLE.BIN.USER <- "genome"
ORACLE.BIN.PWD <- "genome"
ORACLE.BASE <- "/opt/oracle"
ORACLE.HOME <- "/opt/oracle/client/10/run_1"
## ORACLE.LIB <- ":/opt/oracle/client/10/run_1/lib"
## maximum vector length in the IN syntax
#' @export ORACLE.IN.NMAX
ORACLE.IN.NMAX <- 1000L
.conEnv = new.env()


## function to test whether Oracle is available
#' @export hasOracle
hasOracle <- function() {
  return(requireNamespace("ROracle", quietly=TRUE))
}

## onload / onAttach
## .onLoad <- function(libname, pkgname) {}

.onAttach <- function(libname, pkgname) {
  if(hasOracle()) {
    ##    require(ROracle)
    if(!"package:ROracle" %in% search())
      attachNamespace("ROracle")
    obase <- Sys.getenv("ORACLE_BASE")
    ohome <- Sys.getenv("ORACLE_HOME")
    if(identical(obase, "") || identical(obase, ".") || !"client" %in% dir(obase)) {
      Sys.setenv("ORACLE_BASE"=ORACLE.BASE)
    }
    if(identical(ohome, "") || identical(ohome, ".") || !"bin" %in% dir(ohome)) {
      Sys.setenv("ORACLE_HOME"=ORACLE.HOME)
    }
    assign("ORA", ROracle::Oracle(), pos=sys.frame())
  } else {
    ## require(RJDBC)
  }
  con = ribiosCon(db="bin", user=ORACLE.BIN.USER, password=ORACLE.BIN.PWD)
  assign("ORACLE.BIN.CON", con, envir=.conEnv)
}

## automatically establish a connection, depending on whether Oracle client is installed
#' @export ribiosCon
ribiosCon <- function(db="bia", user="biread", password="biread", forceJDBC=FALSE) {
  if(db == "bin" && exists("ORACLE.BIN.CON", envir=.conEnv)) {
      print(sprintf("Using estabilshed database connection to %s", db))
      return(get("ORACLE.BIN.CON", envir=.conEnv))
  } else if(hasOracle() & !forceJDBC) {
    print(sprintf("Estabilshing ROracle connection to %s", db))
    con <- dbConnect(ORA, user = user, password = password, db = db)
  } else {
    print(sprintf("Estabilshin RJDBC connection to %s", db))
    options(java.parameters = "-Xmx4g" ) ## increase the heap size before the RJDBC package is loaded
    suppressWarnings(suppressMessages(hasJDBC <- requireNamespace("RJDBC")))
    if(!hasJDBC)
      stop("No JDBC package installed: please run 'install.packages('RJDBC')' first and then load ribiosAnnotation again.")
    drv <- RJDBC::JDBC("oracle.jdbc.OracleDriver",
                       system.file("drivers", "ojdbc14.jar", package="ribiosAnnotation"))
    port <- switch(EXPR=db, bia=15000, bin=15001)
    str <- paste("jdbc:oracle:thin:", user, "/", password, "@", db, ".kau.roche.com:", port, sep="")
    con <- dbConnect(drv,str)
  }
  return(con)
}

## shortcuts for common connections
newconBIA <- function() ribiosCon(db="bia", user=ORACLE.BIA.USER, password=ORACLE.BIA.PWD)
newconBIA2 <- function() ribiosCon(db="bia", user=ORACLE.BIA2.USER, password=ORACLE.BIA2.PWD)
newconBIARO <- function() ribiosCon(db="bia", user=ORACLE.BIARO.USER, password=ORACLE.BIARO.PWD)
newconBIN <- function() ribiosCon(db="bin", user=ORACLE.BIN.USER, password=ORACLE.BIN.PWD)
newconRED <- function() ribiosCon(db="bin", user=ORACLE.RED.USER, password=ORACLE.RED.PWD)

##----------------------------------------##
## deprecated functions
##----------------------------------------##
biosCurrentGeneSymbol <- function(...) {
  .Deprecated("gtiChipAnnotation",
              package="ribiosAnnotation")
  gtiChipAnnotation(...)
}

raceChipAnnotation <- function(...) {
  .Deprecated("gtiChipAnnotation",
              package="ribiosAnnotation")
  gtiChipAnnotation(...)
}
