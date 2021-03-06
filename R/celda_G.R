# -----------------------------------
# Variable description
# -----------------------------------
# C = Cell
# S or s = Sample
# G = Gene
# TS = Transcriptional State
# CP = Cell population
# n = counts of transcripts
# m = counts of cells
# K = Total number of cell populations
# L = Total number of transcriptional states
# nM = Number of cells
# nG = Number of genes
# nS = Number of samples

# -----------------------------------
# Count matrices descriptions
# -----------------------------------

# All n.* variables contain counts of transcripts
# n.CP.by.TS = Number of counts in each Cellular Population per Transcriptional State
# n.TS.by.C = Number of counts in each Transcriptional State per Cell 
# n.CP.by.G = Number of counts in each Cellular Population per Gene
# n.by.G = Number of counts per gene (i.e. rowSums)
# n.by.TS = Number of counts per Transcriptional State

## All m.* variables contain counts of cells
# m.CP.by.S = Number of cells in each Cellular Population per Sample

# nG.by.TS = Number of genes in each Transcriptional State


#' Calculate the celda_G log likelihood for user-provided cluster assignments
#'
#' This function calculates the log likelihood of each clustering of genes generated
#' over multiple iterations of Gibbs sampling.
#' 
#' @param counts A numeric count matrix
#' @param y A numeric vector of gene cluster assignments
#' @param L The number of clusters being considered
#' @param beta The Dirichlet distribution parameter for Phi; adds a pseudocount to each transcriptional state within each cell
#' @param delta The Dirichlet distribution parameter for Eta; adds a gene pseudocount to the numbers of genes each state
#' @param gamma The Dirichlet distribution parameter for Psi; adds a pseudocount to each gene within each transcriptional state
#' @keywords log likelihood
#' @return The log likelihood of the provided cluster assignment, as calculated by the celda_G likelihood function
#' @export
calculate_loglik_from_variables.celda_G = function(counts, y, L, beta, delta, gamma) {
  n.TS.by.C <- rowsum(counts, group=y, reorder=TRUE)
  
  nM <- ncol(n.TS.by.C)
  
  a <- nM * lgamma(L * beta)
  b <- sum(lgamma(n.TS.by.C + beta))
  c <- -nM * L * lgamma(beta)
  d <- -sum(lgamma(colSums(n.TS.by.C + beta)))
  
  phi.ll <- a + b + c + d

  n.by.G <- rowSums(counts)
  n.by.TS <- as.numeric(rowsum(n.by.G, y))
  
  nG.by.TS <- table(y)
  nG <- nrow(counts)

  a <- sum(lgamma(nG.by.TS * delta))
  b <- sum(lgamma(n.by.G + delta))
  c <- -nG * lgamma(delta)
  d <- -sum(lgamma(n.by.TS + (nG.by.TS * delta)))
  
  psi.ll <- a + b + c + d

  a <- lgamma(L * gamma)
  b <- sum(lgamma(nG.by.TS + gamma))
  c <- -L * lgamma(gamma)
  d <- -sum(lgamma(sum(nG.by.TS + gamma)))

  eta.ll <- a + b + c + d

  final <- phi.ll + psi.ll + eta.ll
  
  return(final)
}


cG.calcLL = function(n.TS.by.C, n.by.TS, n.by.G, nG.by.TS, nM, nG, L, beta, delta, gamma) {
  
  ## Determine if any TS has 0 genes
  ## Need to remove 0 gene states as this will cause the likelihood to fail
  if(sum(nG.by.TS == 0) > 0) {
    ind = which(nG.by.TS > 0)
    L = length(ind)
    n.TS.by.C = n.TS.by.C[ind,]
    n.by.TS = n.by.TS[ind]
    nG.by.TS = nG.by.TS[ind]
  }

  ## Calculate for "Phi" component
  a <- nM * lgamma(L * beta)
  b <- sum(lgamma(n.TS.by.C + beta))
  c <- -nM * L * lgamma(beta)
  d <- -sum(lgamma(colSums(n.TS.by.C + beta)))

  phi.ll <- a + b + c + d

  ## Calculate for "Psi" component
  a <- sum(lgamma(nG.by.TS * delta))
  b <- sum(lgamma(n.by.G + delta))
  c <- -nG * lgamma(delta)
  d <- -sum(lgamma(n.by.TS + (nG.by.TS * delta)))
  
  psi.ll <- a + b + c + d

  ## Calculate for "Eta" component
  a <- lgamma(L * gamma)
  b <- sum(lgamma(nG.by.TS + gamma))
  c <- -L * lgamma(gamma)
  d <- -sum(lgamma(sum(nG.by.TS + gamma)))

  eta.ll <- a + b + c + d

  final <- phi.ll + psi.ll + eta.ll
  return(final)
}




# Calculate Log Likelihood For Single Set of Cluster Assignments (Gene Clustering)
#
# This function calculates the log-likelihood of a given set of cluster assigments for the samples
# represented in the provided count matrix.
# 
# 
# @param n.TS.by.C Number of counts in each Transcriptional State per Cell 
# @param n.by.TS Number of counts per Transcriptional State
# @param nG.by.TS Number of genes in each Transcriptional State
# @param nG.in.Y  Number of genes in each of the cell cluster
# @param gamma The Dirichlet distribution parameter for Psi; adds a pseudocount to each gene within each transcriptional state.
# @param delta The Dirichlet distribution parameter for Eta; adds a gene pseudocount to the numbers of genes each state.
# @param beta Vector of non-zero concentration parameters for cluster <-> gene assignment Dirichlet distribution
# @keywords log likelihood
cG.calcGibbsProbY = function(n.TS.by.C, n.by.TS, nG.by.TS, nG.in.Y, beta, delta, gamma) {
 
  ## Calculate for "Eta" component
  eta.ll <- log(nG.in.Y + gamma)
  
  ## Determine if any TS has 0 genes
  ## Need to remove 0 gene states as this will cause the likelihood to fail
  if(sum(nG.by.TS == 0) > 0) {
    ind = which(nG.by.TS > 0)
    n.TS.by.C = n.TS.by.C[ind,]
    n.by.TS = n.by.TS[ind]
    nG.by.TS = nG.by.TS[ind]
  }
 
  ## Calculate for "Phi" component
  b <- sum(lgamma(n.TS.by.C + beta))
  d <- -sum(lgamma(colSums(n.TS.by.C + beta)))
  phi.ll <- b + d
  
  ## Calculate for "Psi" component
  a <- sum(lgamma(nG.by.TS * delta))
  d <- -sum(lgamma(n.by.TS + (nG.by.TS * delta)))
  psi.ll <- a + d
  
  final <- eta.ll + phi.ll + psi.ll
  return(final)
}



#' celda Gene Clustering Model
#'
#' Provides cluster assignments for all genes in a provided single-cell 
#' sequencing count matrix, using the celda Bayesian hierarchical model.
#' 
#' @param counts A numeric count matrix
#' @param L The number of clusters to generate
#' @param beta The Dirichlet distribution parameter for Phi; adds a pseudocount to each transcriptional state within each cell.
#' @param delta The Dirichlet distribution parameter for Eta; adds a gene pseudocount to the numbers of genes each state. Default to 1.
#' @param gamma The Dirichlet distribution parameter for Psi; adds a pseudocount to each gene within each transcriptional state.
#' @param max.iter Maximum iterations of Gibbs sampling to perform. Defaults to 25.
#' @param count.checksum An MD5 checksum for the provided counts matrix
#' @param y.split.on.iter  On every y.split.on.iter iteration, a heuristic will be applied using hierarchical clustering to determine if a gene cluster should be merged with another gene cluster and a third gene cluster should be split into two clusters. This helps avoid local optimum during the initialization. Default to be 3. 
#' @param y.num.splits Maximum number of times to perform the heuristic described in y.split.on.iter.
#' @param seed Parameter to set.seed() for random number generation.
#' @param best Whether to return the cluster assignment with the highest log-likelihood. Defaults to TRUE. Returns last generated cluster assignment when FALSE. Default to be TRUE. 
#' @param save.history Logical; whether to return the history of cluster assignments. Defaults to FALSE
#' @param save.prob Logical; whether to return the history of cluster assignment probabilities. Defaults to FALSE
#' @param thread The thread index, used for logging purposes
#' @param ...  Additional parameters
#' @keywords LDA gene clustering gibbs
#' @export
celda_G = function(counts, L, beta=1, delta=1, gamma=1, max.iter=25,
                   count.checksum=NULL, seed=12345, best=TRUE, 
                   y.split.on.iter=3,  y.num.splits=3, thread=1, 
                   save.prob=FALSE, save.history=FALSE, ...) {
  
  set.seed(seed)
  message("Thread ", thread, " ", date(), " ... Starting Gibbs sampling")

  y <- sample(1:L, nrow(counts), replace=TRUE)
  y.all <- y

  ## Calculate counts one time up front
  n.TS.by.C = rowsum(counts, group=y, reorder=TRUE)
  n.by.G = rowSums(counts)
  n.by.TS = as.numeric(rowsum(n.by.G, y))
  nG.by.TS = table(y)
  nM = ncol(counts)
  nG = nrow(counts)
  
  ## Calculate initial log likelihood
  ll <- cG.calcLL(n.TS.by.C=n.TS.by.C, n.by.TS=n.by.TS, n.by.G=n.by.G, nG.by.TS=nG.by.TS, nM=nM, nG=nG, L=L, beta=beta, delta=delta, gamma=gamma)
  
  y.probs <- matrix(NA, nrow=nrow(counts), ncol=L)
  iter <- 1
  continue = TRUE
  y.num.of.splits.occurred = 1
  while(iter <= max.iter & continue == TRUE) {
    
    ## Begin process of Gibbs sampling for each cell
    ix <- sample(1:nrow(counts))
    for(i in ix) {
        
	  ## Subtract current gene counts from matrices
	  nG.by.TS[y[i]] = nG.by.TS[y[i]] - 1
	  n.by.TS[y[i]] = n.by.TS[y[i]] - n.by.G[i]
	  n.TS.by.C[y[i],] = n.TS.by.C[y[i],] - counts[i,]

	  ## Calculate probabilities for each state
	  probs = rep(NA, L)
	  for(j in 1:L) {
		temp.nG.by.TS = nG.by.TS
		temp.n.by.TS = n.by.TS
		temp.n.TS.by.C = n.TS.by.C
	  
		temp.nG.by.TS[j] = temp.nG.by.TS[j] + 1
		temp.n.by.TS[j] = temp.n.by.TS[j] + n.by.G[i]
		temp.n.TS.by.C[j,] = temp.n.TS.by.C[j,] + counts[i,]
	  
		probs[j] <- cG.calcGibbsProbY(n.TS.by.C=temp.n.TS.by.C, n.by.TS=temp.n.by.TS, nG.by.TS=temp.nG.by.TS, nG.in.Y=temp.nG.by.TS[j], beta=beta, delta=delta, gamma=gamma)
	  }
	
	  ## Sample next state and add back counts
	  previous.y = y
	  y[i] <- sample.ll(probs)
	  nG.by.TS[y[i]] = nG.by.TS[y[i]] + 1
	  n.by.TS[y[i]] = n.by.TS[y[i]] + n.by.G[i]
	  n.TS.by.C[y[i],] = n.TS.by.C[y[i],] + counts[i,]

      ## Perform check for empty clusters; Do not allow on last iteration
      if(sum(y == previous.y[i]) == 0 & iter < max.iter & L > 2) {
        
        ## Split another cluster into two
        y = split.y(counts=counts, y=y, empty.L=previous.y[i], L=L, LLFunction="calculate_loglik_from_variables.celda_G", beta=beta, delta=delta, gamma=gamma)
        
        ## Re-calculate variables
        n.TS.by.C = rowsum(counts, group=y, reorder=TRUE)
        n.by.TS = as.numeric(rowsum(n.by.G, y))
        nG.by.TS = table(y)
      }

      y.probs[i,] <- probs
    }

    ## Perform split if on i-th iteration defined by y.split.on.iter
    if(iter %% y.split.on.iter == 0 & y.num.of.splits.occurred <= y.num.splits & L > 2) {

      message("Thread ", thread, " ", date(), " ... Determining if any gene clusters should be split (", y.num.of.splits.occurred, " of ", y.num.splits, ")")
      y = split.each.y(counts=counts, y=y, L=L, beta=beta, delta=delta, gamma=gamma, LLFunction="calculate_loglik_from_variables.celda_G")
      y.num.of.splits.occurred = y.num.of.splits.occurred + 1

      ## Re-calculate variables
      n.TS.by.C = rowsum(counts, group=y, reorder=TRUE)
      n.by.TS = as.numeric(rowsum(n.by.G, y))
      nG.by.TS = table(y)
   }
    
    ## Save history
    y.all <- cbind(y.all, y)
    
    ## Calculate complete likelihood
    temp.ll <- cG.calcLL(n.TS.by.C=n.TS.by.C, n.by.TS=n.by.TS, n.by.G=n.by.G, nG.by.TS=nG.by.TS, nM=nM, nG=nG, L=L, beta=beta, delta=delta, gamma=gamma)
    if((best == TRUE & all(temp.ll > ll)) | iter == 1) {
      y.probs.final = y.probs
    }
    ll <- c(ll, temp.ll)

    message("Thread ", thread, " ", date(), " ... Completed iteration: ", iter, " | logLik: ", temp.ll)

    iter <- iter + 1    
  }
  
  
  if(best == TRUE) {
    ix <- which.max(ll)
    y.final <- y.all[,ix]
    ll.final <- ll[ix]
  } else {
    y.final <- y
    ll.final <- tail(ll, n=1)
  }
  
  reordered.labels = reorder.label.by.size(y.final, L)
  y.final.order = reordered.labels$new.labels
  names = list(row=rownames(counts), column=colnames(counts))  

  result = list(y=y.final.order, complete.y=y.all, completeLogLik=ll, 
                finalLogLik=ll.final, L=L, beta=beta, delta=delta, 
                count.checksum=count.checksum, seed=seed, names=names)
  
  if (save.prob) result$y.probability = y.probs else result$y.probability = NA
  if (save.history) {
    result$complete.y =  y.all = base::apply(y.all, 2, function(column) reordered.labels$map[column])
  } 
  
  class(result) = "celda_G"
  return(result)
}


#' Simulate cells from the gene clustering generative model
#'
#' Generate a simulated count matrix, based off a generative distribution whose 
#' parameters can be provided by the user.
#' 
#' @param C The number of cells
#' @param L The number of transcriptional states
#' @param N.Range Vector of length 2 given the range (min,max) of number of counts for each cell to be randomly generated from the uniform distribution
#' @param G The number of genes for which to simulate counts
#' @param beta The Dirichlet distribution parameter for Phi; adds a pseudocount to each transcriptional state within each cell
#' @param delta The Dirichlet distribution parameter for Psi; adds a pseudocount to each gene within each transcriptional state
#' @param gamma The Dirichlet distribution parameter for Psi; adds a pseudocount to each gene within each transcriptional state.
#' @param seed Parameter to set.seed() for random number generation
#' @export
simulateCells.celda_G = function(C=100, N.Range=c(500,5000),  G=1000, 
                                         L=5, beta=1, gamma=1, delta=1, seed=12345) {
  set.seed(seed)
  eta = gtools::rdirichlet(1, rep(gamma, L))
  
  y = sample(1:L, size=G, prob=eta, replace=TRUE)
  if(length(table(y)) < L) {
    stop("Some states did not receive any genes after sampling. Try increasing G and/or setting gamma > 1.")
  }
  y = reorder.label.by.size(y, L)$new.labels
  
  psi = matrix(0, nrow=G, ncol=L)
  for(i in 1:L) {
    ind = y == i
    psi[ind,i] = gtools::rdirichlet(1, rep(delta, sum(ind)))
  }
  
  phi = gtools::rdirichlet(C, rep(beta, L))
  
  ## Select number of transcripts per cell
  nN = sample(N.Range[1]:N.Range[2], size=C, replace=TRUE)
  
  ## Select transcript distribution for each cell
  cell.counts = matrix(0, nrow=G, ncol=C)
  for(i in 1:C) {
    cell.dist = rmultinom(1, size=nN[i], prob=phi[i,])
    for(j in 1:L) {
      cell.counts[,i] = cell.counts[,i] + rmultinom(1, size=cell.dist[j], prob=psi[,j])
    }
  }
  
  ## Ensure that there are no all-0 rows in the counts matrix, which violates a celda modeling
  ## constraint (columns are guarnteed at least one count):
  zero.row.idx = which(rowSums(cell.counts) == 0)
  cell.counts = cell.counts[-zero.row.idx, ]
  y = y[-zero.row.idx]
    

  return(list(y=y, counts=cell.counts, L=L, beta=beta, delta=delta, gamma=gamma, phi=phi, psi=psi, eta=eta, seed=seed))
}





#' Generate factorized matrices showing each feature's influence on the celda_G model clustering 
#' 
#' @param counts A numeric count matrix
#' @param celda.obj Object return from celda_C function
#' @param type A character vector containing one or more of "counts", "proportions", or "posterior". "counts" returns the raw number of counts for each entry in each matrix. "proportions" returns the counts matrix where each vector is normalized to a probability distribution. "posterior" returns the posterior estimates which include the addition of the Dirichlet concentration parameter (essentially as a pseudocount).
#' @export
factorizeMatrix.celda_G = function(counts, celda.obj, type=c("counts", "proportion", "posterior")) {

  L = celda.obj$L
  y = celda.obj$y
  beta = celda.obj$beta
  delta = celda.obj$delta
  
  counts.list = c()
  prop.list = c()
  post.list = c()
  res = list()
  
  n.TS.by.C = rowsum(counts, group=y, reorder=TRUE)
  n.by.G = rowSums(counts)
  n.by.TS = as.numeric(rowsum(n.by.G, y))

  n.G.by.TS = matrix(0, nrow=length(y), ncol=L)
  for(i in 1:length(y)) {n.G.by.TS[i,y[i]] = n.by.G[i]}

  L.names = paste0("L", 1:L)
  colnames(n.TS.by.C) = celda.obj$names$column
  rownames(n.TS.by.C) = L.names
  colnames(n.G.by.TS) = L.names
  rownames(n.G.by.TS) = celda.obj$names$row
  
  if(any("counts" %in% type)) {
    counts.list = list(cell.states=n.TS.by.C, gene.states=n.G.by.TS)
    res = c(res, list(counts=counts.list))
  }
  if(any("proportion" %in% type)) {
    prop.list = list(cell.states = normalizeCounts(n.TS.by.C, scale.factor=1),
    							  gene.states = normalizeCounts(n.G.by.TS, scale.factor=1))
    res = c(res, list(proportions=prop.list))
  }
  if(any("posterior" %in% type)) {
    post.list = list(cell.states = normalizeCounts(n.TS.by.C + beta, scale.factor=1),
    						    gene.states = normalizeCounts(n.G.by.TS + delta, scale.factor=1))
    res = c(res, posterior = list(post.list))						    
  }
  
  return(res)
}



################################################################################
# celda_G S3 methods                                                           #
################################################################################
#' finalClusterAssignment for celda Gene clustering model
#' @param celda.mod A celda model object of class "celda_G"
#' @export
finalClusterAssignment.celda_G = function(celda.mod) {
  return(celda.mod$y)
}

#' completeClusterHistory for celda Gene clustering model
#' @param celda.mod A celda model object of class "celda_G"
#' @export
completeClusterHistory.celda_G = function(celda.mod) {
  return(celda.mod$complete.y)
}

#' clusterProbabilities for celda Gene clustering model
#' @param celda.mod A celda model object of class "celda_G"
#' @export
clusterProbabilities.celda_G = function(celda.mod) {
  return(celda.mod$y.probability)
}


#' getK for celda Gene clustering model
#' @param celda.mod A celda model object of class "celda_G"
#' @export
getK.celda_G = function(celda.mod) { return(NA) }

#' getL for celda Gene clustering model
#' @param celda.mod A celda model object of class "celda_G"
#' @export
getL.celda_G = function(celda.mod) {
  return(celda.mod$L)
}

#' celda_heatmap for celda Gene clustering model
#' @param celda.mod A celda model object of class "celda_G"
#' @param counts A numeric count matrix
#' @param ... extra parameters passed onto render_celda_heatmap
#' @export
celda_heatmap.celda_G = function(celda.mod, counts, ...) {
  render_celda_heatmap(counts, y=celda.mod$y, ...)
}


# TODO DRYer implementation in concert with celda_C
#' visualize_model_performance for the celda Gene function
#' @param celda.list A celda_list object returned from celda()
#' @param method One of "perplexity", "harmonic", or "loglik"
#' @param title Title for the plot
#' @import Rmpfr
#' @export
visualize_model_performance.celda_G = function(celda.list, method="perplexity", 
                                               title="Model Performance (All Chains)") {
  
  cluster.sizes = unlist(lapply(celda.list$res.list, function(mod) { getL(mod) }))
  log.likelihoods = lapply(celda.list$res.list,
                           function(mod) { completeLogLikelihood(mod) })
  performance.metric = lapply(log.likelihoods, 
                              calculate_performance_metric,
                              method)
  
  # These methods return Rmpfr numbers that are extremely small and can't be 
  # plotted, so log 'em first
  if (method %in% c("perplexity", "harmonic")) {
    performance.metric = lapply(performance.metric, log)
    performance.metric = new("mpfr", unlist(performance.metric))
    performance.metric = as.numeric(performance.metric)
  }
  
  plot.df = data.frame(size=cluster.sizes,
                       metric=performance.metric)
  return(render_model_performance_plot(plot.df, "L", method, title))
}
