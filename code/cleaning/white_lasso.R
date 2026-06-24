rm(list = ls())
set.seed(6232025)

.locked_package_helper <- c(
  "code/dependencies/locked_packages.R",
  "dependencies/locked_packages.R",
  "../dependencies/locked_packages.R",
  "../../dependencies/locked_packages.R"
)
.locked_package_helper <- .locked_package_helper[file.exists(.locked_package_helper)][1]
if (is.na(.locked_package_helper)) {
  stop("Could not find code/dependencies/locked_packages.R.")
}
source(.locked_package_helper)
enforce_locked_packages()

packages <-
  c('haven',
    'ggplot2',
    'dplyr',
    'tidyr',
    'data.table',
    'stargazer',
    'randomForest',
    'glmnet',
    'rpart',
    'parallel',
    'stringr')

for (pkg in packages) {
  if (require(pkg, character.only = TRUE) == FALSE) {
    print(paste0("Trying to install ", pkg))
    install.packages(pkg)
    if (require(pkg, character.only = TRUE)) {
      print(paste0(pkg, " installed and loaded"))
    } else{
      stop(paste0("could not install ", pkg))
    }
  }
}
getwd()
# Get paths
paths <- read.csv("../../paths.csv")
CLEANDATA <- paths[paths$global == "CLEANDATA",2]
RAWDATA <- paths[paths$global == "RAWDATA",2]
INTDATA <- paths[paths$global == "INTDATA",2]
XWALKS <- paths[paths$global == "XWALKS",2]

train = read_dta(paste0(INTDATA,'/dcourt/south_county_white_migration_dataset_for_prediction_1950.dta'))

x = model.matrix(~., data=train %>% select(-netwmig))
y = train$netwmig
lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
tmp_coeffs<-coef(lassoPred, s="lambda.min")
lasso_list_of_vars_1950<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)

write.csv(lasso_list_of_vars_1950[2:dim(lasso_list_of_vars_1950)[1],1:dim(lasso_list_of_vars_1950)[2]], file=paste0(INTDATA,'/dcourt/lasso_list_of_vars_white_1950.csv'))

train = read_dta(paste0(INTDATA,'/dcourt/south_county_white_migration_dataset_for_prediction_1960.dta'))

x = model.matrix(~., data=train %>% select(-netwmig))
y = train$netwmig
lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
tmp_coeffs<-coef(lassoPred, s="lambda.min")
lasso_list_of_vars_1960<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)

write.csv(lasso_list_of_vars_1960[2:dim(lasso_list_of_vars_1960)[1],1:dim(lasso_list_of_vars_1960)[2]], file=paste0(INTDATA,'/dcourt/lasso_list_of_vars_white_1960.csv'))

train = read_dta(paste0(INTDATA,'/dcourt/south_county_white_migration_dataset_for_prediction_1970.dta'))

x = model.matrix(~., data=train %>% select(-netwmig))
y = train$netwmig
lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
tmp_coeffs<-coef(lassoPred, s="lambda.min")
lasso_list_of_vars_1970<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)

write.csv(lasso_list_of_vars_1970[2:dim(lasso_list_of_vars_1970)[1],1:dim(lasso_list_of_vars_1970)[2]], file=paste0(INTDATA,'/dcourt/lasso_list_of_vars_white_1970.csv'))
