#' Estimate Skew-t Distribution for MCMCTree
#'
#' Estimate the shape, scale, and location paramaters of a skew-t distribution and output trees for MCMCTree input
#' @param minAge vector of minimum age bounds for nodes matching order in monoGroups
#' @param maxAge vector of maximum age bounds for nodes matching order in monoGroups
#' @param monoGroups list  with each element containing species that define a node of interest
#' @param phy fully resolved phylogeny in ape format
#' @param shape shape value for skew-t distribution (default = 50)
#' @param scale scale value for skew-t distribution (default = 1.5)
#' @param df degrees of freedom for skew-t distribution (default = 1)
#' @param addMode addition to the minimum age to give the location of the distribution
#' @param maxProb probability of right tail (maximum bound default = 0.975) 
#' @param estimateScale logical specifying whether to estimate scale with a given shape value (default = TRUE)
#' @param estimateShape logical specifying whether to estimate shape with a given scale value (default = TRUE)
#' @param estimateMode logical speciftying whether to estimate the scale that produces probabilities of each tail that corresponds roughly to the values given by minProb (lower tail) and maxProb (upper tail)
#' @param plot logical specifying whether to plot to PDF
#' @param pdfOutput pdf output file name
#' @param writeMCMCTree logical whether to write tree in format that is compatible with mcmcTree to file
#' @param mcmcTreeName mcmcTree output file name
#' @keywords 
#' @return list containing node estimates for each distribution
#' \itemize{
#'  \item{"parameters"}{ estimated parameters for each node}
#'  \item{"apePhy"}{ phylogeny in ape format with node labels showing node distributions}
#'  \item{"mcmctree"}{ phylogeny in MCMCTree format}
#'  \item{"nodeLabels"}{ node labels in MCMCTreeR format}
#' }
#' @return If plot=TRUE plot of distributions in file 'pdfOutput' written to current working directory
#' @return If writeMCMCTree=TRUE tree in MCMCTree format in file "mcmcTreeName" written to current working directory
#' @export
#' @examples
#' apeTree <- read.tree(text="((((human, (chimpanzee, bonobo)), gorilla), (orangutan, sumatran)), gibbon);")
#' monophyleticGroups <- list()
#' monophyleticGroups[[1]] <- c("human", "chimpanzee", "bonobo", "gorilla", "sumatran", "orangutan", "gibbon")
#' monophyleticGroups[[2]] <- c("human", "chimpanzee", "bonobo", "gorilla")
#' monophyleticGroups[[3]] <- c("human", "chimpanzee", "bonobo")
#' monophyleticGroups[[4]] <- c("sumatran", "orangutan")
#' minimumTimes <- c("nodeOne"=15, "nodeTwo"=6, "nodeThree"=8, "nodeFour"=13) / 10
#' maximumTimes <- c("nodeOne"=30, "nodeTwo"=12, "nodeThree"=12, "nodeFour"=20) / 10
#' estimateSkewT(minAge=minimumTimes, maxAge=maximumTimes, monoGroups=monophyleticGroups, phy=apeTree, plot=F)

estimateSkewT <- function(minAge, maxAge, monoGroups, phy, shape=50, scale=1.5, df=1, addMode=0, maxProb=0.975, minProb=0.003, estimateScale=TRUE, estimateShape=FALSE, estimateMode=F, plot=FALSE, pdfOutput="skewTPlot.pdf", writeMCMCTree=FALSE, mcmcTreeName="skewTInput.tre")	{

	lMin <- length(minAge)
	lMax <- length(maxAge)
	if(lMin != lMax) stop("length of ages do not match")
	if(length(df) < lMin) { df <- rep_len(df, lMin) ; }
	if(length(minProb) < lMin) { minProb <- rep_len(minProb, lMin) ; print("warning - minProb parameter value recycled") }
	if(length(maxProb) < lMin) { maxProb <- rep_len(maxProb, lMin) ; print("warning - maxProb parameter value recycled") }
	if(length(estimateScale) < lMin) { estimateScale <- rep_len(estimateScale, lMin) ; print("warning - estimateScale argument recycled") }
	if(length(estimateShape) < lMin) { estimateShape <- rep_len(estimateShape, lMin) ; print("warning - estimateShape argument recycled") }
	if(length(estimateMode) < lMin) { estimateMode <- rep_len(estimateMode, lMin); print("warning - estimateMode argument recycled") }

	if(length(shape) < lMin) { 
		shape <- rep_len(shape, lMin)
		if(any(estimateMode) || any(estimateScale)) print("warning - shape parameter value recycled")
		}
	if(length(scale) < lMin) { 
		scale <- rep_len(scale, lMin)
		if(any(estimateShape)) print("warning - scale parameter value recycled")
		}
	if(length(addMode) < lMin) { 
		addMode <- rep_len(addMode, lMin)
		if(any(estimateMode) == F) print("warning - addMode parameter value recycled")
		}	

	nodeFun <- function(x)	{
		upperEsts <- lowerEsts <- c()
		dfInt <- df[x]
		shapeInt <- shape[x]
		scaleInt <- scale[x]
		addModeInt <- addMode[x]
		estimateModeInt <- estimateMode[x]
		estimateShapeInt <- estimateShape[x]
		estimateScaleInt <- estimateScale[x]
		locationInt <- minAge[x] + addMode[x]
		maxProbInt <- maxProb[x]
		minProbInt <- minProb[x]
		
		
		if(estimateModeInt == T) {
			estimateScaleInt=F ; estimateShapeInt=F
		}
		if(estimateShapeInt == T && estimateScaleInt == T) stop("need to set scale or shape")

		
		if(estimateShapeInt == F && estimateScaleInt == F && estimateModeInt == F) {
			
			scaleInt <- scaleInt ; shapeInt <- shapeInt
			} else
			{
								
			if(estimateModeInt) {
				scaleTest <- seq (0.01, 2, by=1e-2)
				locTest <- seq(0.01, 1, by=0.01)
				for(y in 1:length(locTest)) {
					locationInt <- minAge[x] + locTest[y]
					for(u in 1:length(scaleTest)) {
						upperEsts[u] = qst(maxProbInt, xi=locationInt, omega=scaleTest[u], alpha=shapeInt, nu=dfInt)
						lowerEsts[u] = qst(minProbInt, xi=locationInt, omega=scaleTest[u], alpha=shapeInt, nu=dfInt)
						}
						
					closest <- which(abs(upperEsts-maxAge[x])==min(abs(upperEsts-maxAge[x])))
					closest2 <- which(abs(lowerEsts-minAge[x])==min(abs(lowerEsts-minAge[x])))
					if(sum(match(closest, ((closest2-2):(closest2+2))), na.rm=T) != 0) break()
					}
				
				if(sum(match(closest, ((closest2-2):(closest2+2))), na.rm=T) == 0) stop("offset and scale combination not found for skew t distrbution. Maybe change shape and try again")
				upperEst <- round(upperEsts[closest], 2)
				lowerEst <- round(lowerEsts[closest2], 2)
				scaleInt <- round(scaleTest[closest], 2)
				locationInt <- round(locTest[y] + minAge[x], 2)
				} 	
					
			if(estimateScaleInt) {
			
				scaleTest <- seq (0.001, 10, by=1e-3)
				for(u in 1:length(scaleTest)) upperEsts[u] = qst(maxProbInt, xi=locationInt, omega=scaleTest[u], alpha=shapeInt, nu=dfInt)
				closest <- which(abs(upperEsts-maxAge[x])==min(abs(upperEsts-maxAge[x])))
				upperEst <- upperEsts[closest]
				if(abs(maxAge[x]- upperEst) > 0.5) print(paste("warning! node ", x, "upper age over 0.5 Myrs from 97.5% tail - consider changing input shape value"))
				scaleEst <- scaleTest[closest]
				scaleInt <- scaleEst
				}		
		
			if(estimateShapeInt) {

				shapeTest <- seq (1, 50, by=50)
				for(u in 1:length(shapeTest)) upperEsts[u] = qst(maxProbInt, xi=locationInt, omega=scaleInt, alpha=shapeTest[u], nu=dfInt)
				closest <- which(abs(upperEsts-maxAge[x])==min(abs(upperEsts-maxAge[x])))
				upperEst <- upperEsts[closest]
				if(abs(maxAge[x] - upperEst) > 0.5) print(paste("warning! node ", x, "upper age over 0.5 Myrs from 97.5% tail - consider changing input scale value"))
				shapeEst <- shapeTest[closest]
				shapeInt <- shapeEst
				}	
			}
			
			
			nodeCon <- paste0("'ST[", locationInt, "~", scaleInt, "~", shapeInt, "~",  dfInt, "]'")
			parameters <- c(locationInt, scaleInt, shapeInt, dfInt)
			names(parameters) <- c("location", "scale", "shape", "df")
			return(list(nodeCon, parameters))
			}
		
	out <- sapply(1:lMin, nodeFun)
	output <- c()
	
	prm <- matrix(unlist(out[2,]), ncol=4, byrow=T)
	rownames(prm) <- paste0("node_", 1:lMin)
	colnames(prm) <-  c("location", "scale", "shape", "df")
	output$parameters <- prm
	
	output$apePhy <- nodeToPhy(phy, monoGroups, nodeCon=unlist(out[1,]), T) 
	output$mcmctree <- nodeToPhy(phy, monoGroups, nodeCon=unlist(out[1,]), F) 
	if(writeMCMCTree == T) {
		outputTree <- nodeToPhy(phy, monoGroups, nodeCon=unlist(out[1,]), returnPhy=F) 
		write.table(outputTree, paste0(mcmcTreeName), quote=F, row.names=F, col.names=F)
		}
	if(plot == T) {
		if(length(list.files(pattern=paste0(pdfOutput))) != 0) {
			cat(paste0("warning - deleting and over-writing file ", pdfOutput))
			file.remove(paste0(pdfOutput))
			}
	 	pdf(paste0(pdfOutput), family="Times")
		for(k in 1:dim(prm)[1]) {
			plotMCMCTree(prm[k,], method="skewT",  paste0(rownames(prm)[k], " skewT"), upperTime = max(maxAge)+1)
			}
		dev.off()
		}	
		
	output$nodeLabels <- unlist(out[1,])	
	return(output)
}	