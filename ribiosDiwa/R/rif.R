RIFscore <- function(matrix,
                     reg.ind, de.ind=1:nrow(matrix),
                     fac, coefs,
                     method=c("spearman", "pearson", "kendall"),
                     permutation=NULL) {
  if(missing(de.ind))
    de.ind <- 1:nrow(matrix)

  isTwoLevel <- nlevels(fac)==2
  if(missing(coefs)) {
    if(!isTwoLevel)
      stop("More than two groups of samples, no coefs to build contrasts\n")
    coefs <- levels(fac)
  } else {
    haltifnot(length(coefs)==2 & is.character(coefs) & all(coefs %in% levels(fac)),
              msg="'coef' must be a vector of two characters, giving levels of 'fac' to be compared.")
  }

  isX <- fac==coefs[1]
  isY <- fac==coefs[2]
  xReg <- matrix[reg.ind, isX, drop=FALSE]
  yReg <- matrix[reg.ind, isY, drop=FALSE]
  xDe <- matrix[de.ind, isX, drop=FALSE]
  yDe <- matrix[de.ind, isY, drop=FALSE]

  ## RIF1
  RIF1 <- rif1Mat(xReg=xReg, yReg=yReg,
                  xDe=xDe, yDe=yDe, method=method)
  ## RIF2
  RIF2 <- rif2Mat(xReg=xReg, yReg=yReg,
                  xDe=xDe, yDe=yDe, method=method)
  
  res <- data.frame(Index=reg.ind,
                    RIF1=RIF1,
                    RIF2=RIF2,
                    RIF1.rank=rank(RIF1),
                    RIF2.rank=rank(RIF2),
                    RIF1.pos.p=NA,
                    RIF1.neg.p=NA,
                    RIF2.pos.p=NA,
                    RIF2.neg.p=NA)
  
  ## Calculate p values by sample permutation
  if(!is.null(permutation)) {
    N <- as.integer(permutation)
    bRIFs <- lapply(1:N, function(x) {
      isXY <- sample(1:ncol(matrix),
                     sum(fac %in% c(coefs[1], coefs[2])), replace=FALSE)
      isX <- isXY[1:sum(fac==coefs[1])]
      isY <- setdiff(isXY, isX)

      ## calculate diff
      diffEst <- abs(rowMeans(matrix[,isX, drop=FALSE])-rowMeans(matrix[,isY,drop=FALSE]))
      newDe <- rank(diffEst) >= length(diffEst) - length(de.ind) + 1

      xReg <- matrix[reg.ind, isX, drop=FALSE]
      yReg <- matrix[reg.ind, isY, drop=FALSE]
      xDe <- matrix[newDe, isX, drop=FALSE]
      yDe <- matrix[newDe, isY, drop=FALSE]

      ## RIF1
      RIF1 <- rif1Mat(xReg=xReg, yReg=yReg,
                      xDe=xDe, yDe=yDe, method=method)
      ## RIF2
      RIF2 <- rif2Mat(xReg=xReg, yReg=yReg,
                      xDe=xDe, yDe=yDe, method=method)
      return(matrix(c(RIF1, RIF2), byrow=FALSE, ncol=2))
    })
    for(i in seq(along=reg.ind)) {
      res$RIF1.neg.p[i] <- empval(res[i, 2], sapply(bRIFs, function(x) x[i, 1]))
      res$RIF1.pos.p[i] <- 1-res$RIF1.neg.p[i]
      res$RIF2.neg.p[i] <- empval(res[i, 3], sapply(bRIFs, function(x) x[i, 2]))
      res$RIF2.pos.p[i] <- 1-res$RIF2.neg.p[i]
    }
  }
  res <- res[with(res, order((RIF1.rank+RIF2.rank)/2)),,drop=FALSE]
  return(res)
}
