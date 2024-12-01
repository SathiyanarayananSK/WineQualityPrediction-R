#####################################
#Question 1 - Understanding the Data
#####################################


# Importing necessary libraries
library(ggplot2)  # For data visualization
library(e1071)    # For skewness calculation
source("AggWaFit718.R")  # Custom function for fitting models

# Loading the data set and seeding with student ID
data.raw <- as.matrix(read.table("RedWine.txt"))
set.seed(223789819)

# Sampling 500 rows from the data set
data.subset <- data.raw[sample(1:1599, 500), c(1:6)]

# Defining variable names
data.variable.names <- c("citric acid", "chlorides", "total sulfur dioxide", "pH", "alcohol", "Y")

# Assigning variable names to the subset of data
colnames(data.subset) <- data.variable.names

# Function to create 5 scatterplots for each X variable against the variable of interest Y
create_scatterplots <- function(data, variable_names) {
  for (i in 1:5) {
    plot(data[, i], data[, 6], xlab = variable_names[i], ylab = variable_names[6], main = paste("Scatterplot of", variable_names[i], "vs Y"), cex.main = 1.5, cex.lab = 1.5, cex.axis = 1.5)
  }
}

# Function to create 6 histograms for each X variable and Y
create_histograms <- function(data, variable_names) {
  for (i in 1:6) {
    hist(data[, i], main = variable_names[i], xlab = "Value", ylab = "Frequency", col = "skyblue", border = "white", cex.main = 1.2, cex.lab = 1.2, cex.axis = 1.2)
  }
}

# Calling the functions to create scatterplots and histograms
create_scatterplots(data.subset, data.variable.names)
create_histograms(data.subset, data.variable.names)


####################################
#Question 2 - Transforming the Data
####################################


# Choosing variables for transformation and obtaining a 500 by 5 matrix
I <- c("citric acid", "total sulfur dioxide", "pH", "alcohol", "Y")
variables_for_transform <- data.subset[,I]  

# Creating a 500 by 5 NA data set and assigning the column names to store the transformed data
data.transformed <- matrix(NA, nrow = nrow(variables_for_transform), ncol = ncol(variables_for_transform))
colnames(data.transformed) <- I

# Calculating and appending skewness for each variable
skewness_values_list <- list()
for (i in 1:5) {
  skewness_value <- skewness(variables_for_transform[, i])
  skewness_values_list[[i]] <- skewness_value
  cat("Skewness of", colnames(variables_for_transform)[i], ":", skewness_value, "\n")
}

# Initializing an empty list to store transformations
transformations_list <- list()

# Applying transformations based on skewness
for (i in 1:length(skewness_values_list)) {
  the_value <- skewness_values_list[[i]]
  
  # Positive skewness
  if (the_value >= 0) {
    if (the_value < 0.3) {
      transformation <- "none"
      data.transformed[, i] <- variables_for_transform[, i]
    } else if (any(variables_for_transform[,i] == 0)) {
      transformation <- "square_root"
      data.transformed[, i] <- variables_for_transform[, i]^0.5
    } else {
      transformation <- "log"
      data.transformed[, i] <- log(variables_for_transform[, i])
    }
  } 
  #Negative skewness
  else {
    if (the_value > -0.3) {
      transformation <- "none"
      data.transformed[, i] <- variables_for_transform[, i]
    }
    else{
      transformation <- "p_square"
      data.transformed[, i] <- variables_for_transform[, i]^2}
  }
  
  transformations_list[[i]] <- transformation
}

# Printing the list of transformations
for (i in 1:length(transformations_list)) {
  cat("The transformation applied for", colnames(variables_for_transform)[i], "is", transformations_list[[i]], "\n")
}

# Function for min-max normalisation
minmax <- function(x){
  (x - min(x))/(max(x)-min(x))
}

# Function for z-score standardisation and scaling to unit interval
unit.z <- function(x){
  0.15*((x-mean(x))/sd(x)) + 0.5
}

# Storing the transformed data in 2 variables for further analysis (These variables are used while reversing for prediction)
min_max_data <- data.transformed
original_transformed <- data.transformed

# Applying Min-Max and Z-score transformation to adjust the scale of each variable
for (i in 1:ncol(data.transformed)) {
  data.transformed[, i] <- minmax(data.transformed[, i])
  min_max_data[,i] <- data.transformed[, i]
  data.transformed[, i] <- unit.z(data.transformed[, i])
}

# Identifying and handling negative values
indices_negative <- which(data.transformed < 0, arr.ind = TRUE)
print(indices_negative)
rows_negative_values <- data.transformed[indices_negative[, 1], ]
print(rows_negative_values)
negative_values <- data.transformed < 0
data.transformed[negative_values] <- 0

# Saving this transformed data to a text file
write.table(data.transformed, "sathiyanarayanan-transformed.txt")


################################################
#Question 3 - Building models and investigating
################################################


# Loading the transformed data
data.transformed_copy <- as.matrix(read.table("sathiyanarayanan-transformed.txt"))  

# Getting weights for Weighted Arithmetic Mean with fit.QAM()
fit.QAM(data.transformed_copy, "output_file_WAM.txt", "stats_file_WAM.txt")

# Getting weights for Power Mean p=0.5 with fit.QAM()
fit.QAM(data.transformed_copy, "output_file_PM05.txt", "stats_file_PM05.txt", g=PM05, g.inv = invPM05)

# Getting weights for Power Mean p=2 with fit.QAM()
fit.QAM(data.transformed_copy, "output_file_QM.txt", "stats_file_QM.txt", g=QM, g.inv = invQM)

# Getting weights for Ordered Weighted Average with fit.OWA()
fit.OWA(data.transformed_copy,"output_file_OWA.txt", "stats_file_OWA.txt")


#######################################
#Question 4 - Use Model for Prediction
#######################################

# New input for prediction
new_input <- c(0.9, 0.65, 38, 2.53, 7.1)

# choosing the same four X variables as in Q2
new_input_for_transform <- new_input[c(1, 3, 4, 5)]  
print(new_input_for_transform)

# Creating a variable to store transformed values
new_input_transformed <- new_input_for_transform

# Applying square root  transformation to column 1 and log transformation to column 2 and 4 (Same as the ones applied in Q2)
new_input_transformed[1] <- new_input_for_transform[1]^0.5
for(i in c(2,4)){
  new_input_transformed[i] <- log(new_input_for_transform[i])
  
}

# New input after transformations
print(new_input_transformed)

#Applying Min-Max and Z-score transformation to new input (Same as in Q2)
new_input_transformed <- minmax(new_input_transformed)
new_input_transformed <- unit.z(new_input_transformed)

# New input after all transformations
print(new_input_transformed)


# Applying the transformed variables to the best model selected from Q3 for Y prediction
WAM_Weights = c(0.204653931802187, 0.0222789961748349, 0.0588720047935909, 0.714195067229387)
predicted_value = QAM(new_input_transformed,WAM_Weights)

# Reversing the transformation to convert back the predicted Y to the original scale and then rounding it to integer

#Reversing functions
reverse_unit_z <- function(transformed_value, original_mean, original_sd) {
  (transformed_value - 0.5) / 0.15 * original_sd + original_mean
}
reverse_minmax <- function(transformed_value, original_min, original_max) {
  transformed_value * (original_max - original_min) + original_min
}
reverse_log <- function(y) {
  exp(y)
}

# Variables required for reversing functions
means <- apply(min_max_data, 2, mean)
sds <- apply(min_max_data, 2, sd)
max_values <- apply(original_transformed, 2, max)
min_values <- apply(original_transformed, 2, min)

# Applying reverse in the correct order
reverse_of_z <- reverse_unit_z(predicted_value, means[5], sds[5])
reverse_of_max_min <- reverse_minmax(reverse_of_z, min_values[5], max_values[5])
reverse_of_log <- reverse_log(reverse_of_max_min)

# Displaying the rounded value of the final prediction
final_prediction <- round(reverse_of_log)
cat("The predicted wine quantity for the new inputs is", final_prediction[1], "\n")




###############
# References 
###############

# Dataset:
# Red Wine Quality dataset - Accessed from [1] P. Cortez, A. Cerdeira, F. Almeida, T. Matos and J. Reis. Modeling wine preferences by data mining from physicochemical properties. In Decision Support Systems, Elsevier, 47(4):547-553, 2009.

# Packages:
# ggplot2: Wickham, H. (2016). ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York.
# e1071: Meyer, D., Dimitriadou, E., Hornik, K., Weingessel, A., & Leisch, F. (2020). e1071: Misc Functions of the Department of Statistics, Probability Theory Group (Formerly: E1071), TU Wien. R package version 1.7-4.
# AggWaFit718.R: James, Simon. (2016). AggWAfit R library. 10.13140/RG.2.1.1906.9688. 
