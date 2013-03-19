###########################################################################################################
#READING THE ANNOTATION GPL2986.annot FILE FOR HUMAN GDS3113 DATASET TO GET THE PROBESETS WITH FULL ANNOTATION.
#PROBESETS WITH NO REFERENCE TO GENE SYMBOLS ARE NOT CONSIDERED.
DATA <- strsplit(readLines("GPL2986.annot",n=-1,ok=TRUE,warn=TRUE),"\n")
ndata <- matrix(rep(0,length(DATA)*2),nrow=length(DATA),ncol=2)
for(i in 1:length(DATA)){
     if(regexpr("^([0-9]*)\t",DATA[[i]],perl=TRUE) == TRUE){
          if(strsplit(DATA[[i]],"\t")[[1]][3] == ""){
              ndata[i,2] <- as.matrix(strsplit(DATA[[i]],"\t")[[1]][1])
              ndata[i,1] <- Inf
          }
          else{
              ndata[i,2] <- as.matrix(strsplit(DATA[[i]],"\t")[[1]][1])
              ndata[i,1] <- as.matrix(strsplit(DATA[[i]],"\t")[[1]][3])
          }
     }
}
ndata <- ndata[-which(ndata == "Inf", arr.ind=TRUE)[,1],]
ndata <- ndata[-which(ndata == "0", arr.ind=TRUE)[,1],]
rm(DATA)
#COMBINING ALL PROBESETS OF A GENE
ldata <- split(ndata,1:nrow(ndata))
for(i in 1:length(ldata)){
      count <- 3
      for(j in i:length(ldata)){
          if((ldata[[i]][1] == ldata[[j]][1]) && (ldata[[i]][1] != "NULL") && (i!=j)){
              ldata[[i]][count] <- ldata[[j]][2]
              ldata[[j]][1] <- "NULL"
              count <- count + 1
          }
      }
}
cmax <- 2
for(i in 1:length(ldata)){
      if(cmax < length(ldata[[i]])){
          cmax <- length(ldata[[i]])
      }
}
tdata <- matrix(rep(0,length(ldata)*cmax),nrow=length(ldata),ncol=cmax)
for(i in 1:length(ldata)){
      if(strsplit(ldata[[i]]," ")[[1]][1] != "NULL"){
          for(j in 1:length(ldata[[i]])){
              tdata[i,j] <- as.matrix(strsplit(ldata[[i]]," ")[[j]][1])
          }
      }
      else{
          tdata[i,1] <- Inf
      }
}
tdata <- tdata[-(which(tdata=="Inf",arr.ind=TRUE)[,1]),]
rm(ldata,cmax,ndata)
h_data <- split(tdata,1:nrow(tdata))
rm(tdata)
#PRINT THE FINAL PROBESETS TO A FILE
sink("probe_number_human.txt")
for(i in 1:length(h_data)){
      for(j in 2:length(h_data[[i]])){
          if(h_data[[i]][j] != "0"){
              cat(h_data[[i]][j],'\n')
          }
      }
}
sink()
###########################################################################################################

###########################################################################################################
#READ THE GENE EXPRESSION DATA
data = read.table("exp3113_org.txt")
source("../commonfiles/BFN4.r") #EDIT THE DIRECTORY PATH
source("../commonfiles/BFN3.r") #EDIT THE DIRECTORY PATH
source("../commonfiles/BFN.r") #EDIT THE DIRECTORY PATH
source("../commonfiles/BF.r") #EDIT THE DIRECTORY PATH
#READ THE PROBESETS THAT ARE RELEVANT
probe_number = as.matrix(read.table("probe_number_human.txt",comment.char=""))
#REMOVE THE CELL LINE TISSUES FROM GENE EXPRESSION DATA
data$GSM194459 <- NULL
data$GSM194460 <- NULL
data$GSM194461 <- NULL
data$GSM194468 <- NULL
data$GSM194469 <- NULL
data$GSM194470 <- NULL
data$GSM194474 <- NULL
data$GSM194475 <- NULL
data$GSM194476 <- NULL
data$GSM194516 <- NULL
data$GSM194517 <- NULL
data$GSM194518 <- NULL
data$GSM194522 <- NULL
data$GSM194523 <- NULL
data$GSM194524 <- NULL

###########################################################################################################
#GET THE GENE EXPRESSION DATA FOR THE RELEVANT PROBESETS
DATA = matrix(rep(0,length(probe_number)*ncol(data)),nrow=length(probe_number))
row.names(DATA) <- probe_number
for(i in 1:length(probe_number)){
	for(j in 1:length(row.names(data))){
		if(probe_number[i] == row.names(data)[j]){
			temp<- as.matrix(data[j,])
			DATA[i,] <- t(temp)
		}
	}
}
###########################################################################################################
#PERFORM MODIFIED BAYES FACTOR TO FIND TISSUE SPECIFIC, 2-SELECTIVE, 3-SELECTIVE AND 4-SELECTIVE PROBESETS
#IN THE GENE EXPRESSION DATA. NRREPLIC IS THE NUMBER OF REPLICATES FOR TISSUES IN THE DATA.
nrreplic = rep(3,27)
nrruns = 10000
dat_row <- nrow(DATA)
dat_col <- ncol(DATA)
#GET THE TOP 4 HIGHLY EXPRESSED TISSUES FOR ALL PROBESETS
tissue_specific <- matrix(rep(0,dat_row*length(nrreplic)), nrow = dat_row)
row.names(tissue_specific) <- probe_number
max_tissue <- matrix(rep(0,dat_row*4),nrow=dat_row,ncol=4)
lower <- 1
AV1<-matrix(c(rep(0,nrow(DATA)*ncol(DATA))),nrow=nrow(DATA),ncol=ncol(DATA))
AV2<-matrix(c(rep(0,nrow(DATA)*length(nrreplic))),nrow=nrow(DATA),ncol=length(nrreplic))
for (i in (1:length(nrreplic))){
    		upper<-lower+nrreplic[i]-1
    		v<-rep(1,nrreplic[i])
    		average<-(DATA[,lower:upper])%*%(v*(t(v)%*%v)^(-1))
    		AV1[,lower:upper]<-average%*%t(v)
    		AV2[,i]<-average
    		lower<-upper+1
}
for(i in 1:dat_row){
      max_tissue[i,1] <- which(AV2[i,] == sort(AV2[i,],decreasing=TRUE)[1],arr.ind=TRUE)[1]
      max_tissue[i,2] <- which(AV2[i,] == sort(AV2[i,],decreasing=TRUE)[2],arr.ind=TRUE)[1]
      max_tissue[i,3] <- which(AV2[i,] == sort(AV2[i,],decreasing=TRUE)[3],arr.ind=TRUE)[1]
      max_tissue[i,4] <- which(AV2[i,] == sort(AV2[i,],decreasing=TRUE)[4],arr.ind=TRUE)[1]
}
#RUN THE MODIFIED BAYES FACTOR. NRRUNS IS NUMBER OF TIMES TO RUN BAYES FACTOR FOR EACH PROBESET.
#"1" IN THE FUNCTION IS FOR UP REGULATED (HIGHLY EXPRESSED) GENES. THE LAST PARAMETER IN THE
#BAYES FACTOR IS FOR VARIANCE BETWEEN TISSUES.
bfn4 <- BFN4(DATA,nrreplic,1,nrruns,1.79)
bfn3 <- BFN3(DATA,nrreplic,1,nrruns,1.79)
bfn1 <- BFN(DATA,nrreplic,1,nrruns,1.92)
bf1 <- BF(DATA,nrreplic,1,nrruns,1.79)
#ASSIGN PROBESETS TO THE APPROPRIATE TISSUE SELECTIVE CATEGORY BASED ON THE THRESHOLD
for(i in 1:dat_row){
      if(bfn4[i] > 17549){
              tissue_specific[i,max_tissue[i,1]] = 4
              tissue_specific[i,max_tissue[i,2]] = 4
              tissue_specific[i,max_tissue[i,3]] = 4
              tissue_specific[i,max_tissue[i,4]] = 4
      }
      if(bfn3[i] > 2924 && (tissue_specific[i,max_tissue[i,4]] == 0) && (tissue_specific[i,max_tissue[i,3]] == 0) && (tissue_specific[i,max_tissue[i,2]] == 0) && (tissue_specific[i,max_tissue[i,1]] == 0)){
              tissue_specific[i,max_tissue[i,1]] = 3
              tissue_specific[i,max_tissue[i,2]] = 3
              tissue_specific[i,max_tissue[i,3]] = 3
      }
      if(bfn1[i] > 1200 && (tissue_specific[i,max_tissue[i,4]] == 0) && (tissue_specific[i,max_tissue[i,3]] == 0) && (tissue_specific[i,max_tissue[i,2]] == 0) && (tissue_specific[i,max_tissue[i,1]] == 0)){
              tissue_specific[i,max_tissue[i,1]] = 2
              tissue_specific[i,max_tissue[i,2]] = 2
      }
      if(bf1[i] > 32 && (tissue_specific[i,max_tissue[i,4]] == 0) && (tissue_specific[i,max_tissue[i,3]] == 0) && (tissue_specific[i,max_tissue[i,2]] == 0) && (tissue_specific[i,max_tissue[i,1]] == 0)){
             tissue_specific[i,max_tissue[i,1]] = 1
      }
}
#PRINT THE RESULTS IN TO A FILE FOR FURTHER PROCESSING
k <- 1
sink("human_genes_tissue_specificity_final.txt")
for(i in 1:length(h_data)){
      for(j in 2:length(h_data[[i]])){
          if(h_data[[i]][j] != "0"){
              cat(h_data[[i]][1],'\t',h_data[[i]][j],'\t',tissue_specific[k,],'\n')
              k <- k+1
          }
      }
}
sink()
  

