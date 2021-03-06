matchGenes <- function(x, vec, na.rm=TRUE) {
  if(!is(x, "GeneSets"))
    stop("'x' must be a 'GeneSets' object")
  haltifnot(is.vector(vec),
            msg="'vec' must be a vector of gene names")
  xgl <- gsGenes(x)
  xgenes <- unlist(xgl)
  xgenes[is.na(xgenes) | xgenes=="" | xgenes=="-"] <- NA
  xgenes.ind <- match(xgenes, vec)
  xlens <- sapply(xgl, length)
  xfac <- factor(rep(1:length(xgl), xlens), levels=1:length(xgl))
  gs.indices <- split(xgenes.ind, xfac)
  gs.indices <- lapply(gs.indices, function(x) {
    if(na.rm) x <- x[!is.na(x)]
    return(x)
  })
  names(gs.indices) <- gsName(x)

  return(gs.indices)
}

#' Read GMT file into a GeneSets object
#'
#' @param ... Named or unnamed characater string vector, giving file names of One or more GMT format files. 
#' @param category Character string, category of the gene sets, for instance 'Gene Onotology' or 'Reactome pathway'
#'
#' @examples
#' gmtFile <- system.file("extdata", "example.gmt", package="ribiosGSEA")
#' mySet <- readGmt(gmtFile)
#' myFakeSet <- readGmt(CategoryA=gmtFile, CategoryB=gmtFile)
#' anotherFakeSet <- readGmt(gmtFile, gmtFile, category=c("CategoryA", "CategoryB"))
#' 
readGmt <- function(..., category=NULL) {
    files.list <- list(...)
    files <- unlist(files.list, use.names=TRUE)
    fnames <- names(files)
    if(!is.null(fnames)) {
        if(!is.null(category))
            warning("'file' have names - the category option is ignored")
        category <- fnames
    } else if(is.null(category)) {
        category <- basefilename(files)
    } else if(!is.null(category)) {
        category <- rep(category, length.out=length(files))
    }
    gsList <- lapply(files, read_gmt_list)
    gs <- unlist(gsList, use.names=TRUE, recursive=FALSE)
    category <- rep(category, sapply(gsList, length))
    resl <- lapply(seq(along=gs), function(i) {
                       return(GeneSet(category=category[[i]],
                                      name=gs[[i]]$name,
                                      desc=gs[[i]]$desc,
                                      genes=gs[[i]]$genes))
                   })
    names(resl) <- sapply(resl, gsName)
    res <- GeneSets(resl)
    return(res)
}

#' Write an GeneSet object into a file
#'
#' @param geneSet A GeneSet object
#' @param file Character string, output file name
#'
#' @examples
#' gmtFile <- system.file("extdata", "example.gmt", package="ribiosGSEA")
#' mySet <- readGmt(gmtFile)[1:5]
#' myTempFile <- tempfile()
#' writeGmt(mySet, file=myTempFile)
#' readLines(myTempFile)
writeGmt <- function(geneSet, file) {
    gmtList <- lapply(seq(along=geneSet), function(i) {
                          list(name=gsName(geneSet[[i]]),
                               description=paste(gsCategory(geneSet[[i]]), gsDesc(geneSet[[i]]), sep="|"),
                               genes=gsGenes(geneSet[[i]]))
                      })
    ribiosIO::write_gmt(gmtList, file=file)
}

parseGmt <- function(file, vec, min, max) {
  res <- readGmt(file)
  ind <- matchGenes(res, vec, na.rm=TRUE)

  ## final filtering
  nmin <- ifelse(!missing(min) && is.numeric(min), min, 0)
  nmax <- ifelse(!missing(max) && is.numeric(max), max, Inf)
  ind <- ind[sapply(ind, function(x) length(x)>=nmin & length(x)<=nmax)]
  return(ind)
}
