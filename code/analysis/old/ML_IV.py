
import numpy as np
import pandas as pd
import os
import numpy as np
from scipy import special
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.ensemble import RandomForestRegressor
import matplotlib.pyplot as plt
import patsy
from econml.iv.dml import OrthoIV, DMLIV, NonParamDMLIV
from econml.iv.dr import LinearDRIV, SparseLinearDRIV, ForestDRIV, LinearIntentToTreatDRIV
from tabulate import tabulate
import random
import matplotlib.pyplot as plt
from scipy import stats

def addStars(p):
    if p>0.1:
        return ""
    elif p<=0.1 and p>0.05:
        return "*"
    elif p<=0.05 and p>0.01:
        return "**"
    elif p<=0.01 and p>0:
        return "***"
    else:
        return "ERROR, P CAN'T BE NEGATIVE"


user = os.getlogin()

if user=="Everett Stamm":
	REPO =  "/Users/Everett Stamm/Documents/GitHub/municipality_proliferation/"
	DROPBOX = "/Users/Everett Stamm/Dropbox/municipality_proliferation/"


RAWDATA =  DROPBOX+"/data/raw"
INTDATA = DROPBOX+"/data/interim"
CLEANDATA =DROPBOX+ "/data/clean"
SUPPDATA = DROPBOX+"/supplemental"
XWALKS = DROPBOX+"/crosswalks"

CODE = REPO+"/code"
ANALYSIS = CODE+"/analysis"
CLEANING = CODE+"/cleaning"
EXHIBITS = REPO+"/exhibits"
FIGS = EXHIBITS+"/figures"
TABS = EXHIBITS+"/tables"

headers = ['OrthoIV',
    'Projected OrthoIV',
    'DMLIV',
    'DRIV']
het_headers = ['OrthoIV',
    'Projected OrthoIV']

data = pd.read_stata(CLEANDATA+"/county_schdist_ind_stacked_full.dta")

random.seed(20230425)
test_fips = data.fips.drop_duplicates().sample(frac = 0.2)
test = data.loc[data.fips.isin(test_fips)]
train = data.loc[(data.fips.isin(test_fips))==False]

for inst in ['hat', 'actfull']:
    for pc in [0,1]:
        if inst=="hat":
            instlab = "Push-Factor"
        else:
            instlab = "Shift-Share"
        ate_results = [['B(GM)',np.nan,np.nan,np.nan,np.nan],
               ['SE(GM)',np.nan,np.nan,np.nan,np.nan]]

        Y = data.n_muni_county_L0.to_numpy().reshape(len(data),1).astype('float64')
        T = data.GM.to_numpy().reshape(len(data),1).astype('float64')
        W = data[['base_muni_county_L0','mfg_lfshare','blackmig3539_share','reg2','reg3','reg4']]
        Z = data['GM_'+inst].to_numpy().reshape(len(data),1).astype('float64')
        
        Y_train = train.n_muni_county_L0.to_numpy().reshape(len(train),1).astype('float64')
        T_train = train.GM.to_numpy().reshape(len(train),1).astype('float64')
        W_train = train[['base_muni_county_L0','mfg_lfshare','blackmig3539_share','reg2','reg3','reg4']]
        Z_train = train['GM_'+inst].to_numpy().reshape(len(train),1).astype('float64')
        
        Y_test = test.n_muni_county_L0.to_numpy().reshape(len(test),1).astype('float64')
        T_test = test.GM.to_numpy().reshape(len(test),1).astype('float64')
        W_test = test[['base_muni_county_L0','mfg_lfshare','blackmig3539_share','reg2','reg3','reg4']]
        Z_test = test['GM_'+inst].to_numpy().reshape(len(test),1).astype('float64')
        
        if pc==1:
            pclab = "Per Capita (100,000)"
            countypop1940 = data.countypop1940.to_numpy().reshape(len(data),1).astype('float64')
            Y = 100000*np.divide(Y,countypop1940)
            countypop1940_train = train.countypop1940.to_numpy().reshape(len(train),1).astype('float64')
            Y_train = 100000*np.divide(Y_train,countypop1940_train)
            countypop1940_test = test.countypop1940.to_numpy().reshape(len(test),1).astype('float64')
            Y_test = 100000*np.divide(Y_test,countypop1940_test)
        else:
            pclab = ""
        ## Average Treatment Effects
        # OrthoIV Estimator
        est1 = OrthoIV(projection=False, discrete_treatment=False, discrete_instrument=False)
        est1.fit(Y, T, Z=Z, X=None, W=W)
        est1.summary(alpha=0.05)
        
        
        ate_results[0][1] = str(round(est1.const_marginal_ate()[0][0],2)) +  addStars(est1.const_marginal_ate_inference().pvalue()[0][0])
        ate_results[1][1] = round(((est1.const_marginal_ate_interval()[1][0][0] - est1.const_marginal_effect_interval()[0][0][0])/3.92)[0],2)



        # Projected OrthoIV Estimator
        est2 = OrthoIV(projection=True, discrete_treatment=False, discrete_instrument=False)
        est2.fit(Y,T,Z=Z,X=None,W=W)
        est2.summary(alpha=0.05)
        
        ate_results[0][2] = str(round(est2.const_marginal_ate()[0][0],2)) +  addStars(est2.const_marginal_ate_inference().pvalue()[0][0])
        ate_results[1][2] = round(((est2.const_marginal_ate_interval()[1][0][0] - est2.const_marginal_effect_interval()[0][0][0])/3.92)[0],2)

        # DMLIV Estimator
        est3 = DMLIV(
            discrete_treatment=False,
            discrete_instrument=False,
        )
        est3.fit(Y, T, Z=Z, X=None, W=W, inference='bootstrap')
        est3.summary()
        ate_results[0][3] = str(round(est3.const_marginal_ate()[0][0],2)) +  addStars(est3.const_marginal_ate_inference().pvalue()[0][0])
        ate_results[1][3] = round(((est3.const_marginal_ate_interval()[1][0][0] - est3.const_marginal_effect_interval()[0][0][0])/3.92)[0],2)

        # Linear DRIV Estimator
        est4 = LinearDRIV(discrete_treatment=False, discrete_instrument=False)
        est4.fit(Y, T, Z=Z, X=None, W=W)
        est4.summary()
        
        ate_results[0][4] = str(round(est4.const_marginal_ate()[0][0],2)) +  addStars(est4.const_marginal_ate_inference().pvalue()[0][0])
        ate_results[1][4] = round(((est4.const_marginal_ate_interval()[1][0][0] - est4.const_marginal_effect_interval()[0][0][0])/3.92)[0],2)

        ate_table = tabulate(ate_results, headers, tablefmt='latex_booktabs')
        # Write the LaTeX code to a file
        with open(TABS+'/ml/ate_results_'+str(pc)+'_GM_'+inst+'.tex', 'w') as f:
            f.write(r"\begin{table}\centering\caption{"+instlab+" instrument, "+pclab+"}")
            f.write(ate_table)
            f.write(r"\end{table}")

            
        ## Heterogeneous Treatment Effects
        for ex in ['co_2020','above_med_land','above_med_unusable', "above_med_total_00", 
                   'above_med_total_05', 'above_med_total_10', 'above_med_total_15', 
                   'above_med_total_20', 'above_med_lu_ml_2010', 'above_med_lu_ml_mean', 
                   'above_med_ub_1', 'above_med_ub_2']:
            het_results = [['B(GM)',np.nan,np.nan],
               ['SE(GM)',np.nan,np.nan],
               ['CATE Intercept',np.nan,np.nan],
               ['CATE SE',np.nan,np.nan]]
            
            X = data[ex].to_numpy().reshape(len(data),1).astype('float64')
            X_train = train[ex].to_numpy().reshape(len(train),1).astype('float64')
            X_test = test[ex].to_numpy().reshape(len(test),1).astype('float64')

            # OrthoIV Estimator
            est1 = OrthoIV(projection=False, discrete_treatment=False, discrete_instrument=False)
            # Full dataset, for tables
            est1.fit(Y, T, Z=Z, X=X, W=W)
            est1.summary(alpha=0.05)
            
            
            het_results[0][1] = str(round(est1.coef_[0][0][0],2)) + addStars(est1.coef__inference().pvalue()[0][0][0])
            het_results[1][1] = round((est1.coef__interval()[1][0][0][0] - est1.coef__interval()[0][0][0][0])/3.92,2)
            het_results[2][1] = str(round(est1.intercept_[0][0],2)) + addStars(est1.intercept__inference().pvalue()[0][0])
            het_results[3][1] = round((est1.intercept__interval()[1][0][0] - est1.intercept__interval()[0][0][0])/3.92,2)
            
            est1.fit(Y_train, T_train, Z=Z_train, X=X_train, W=W_train)
            te_1 = est1.effect(X_train)
            te_1_lb, te_1_ub = est1.effect_interval(X_train, alpha=0.05)
            te_pred1 = est1.effect(X_test)
            te_pred1_lb, te_pred1_ub = est1.effect_interval(X_test, alpha=0.05)

            # Projected OrthoIV Estimator
            est2 = OrthoIV(projection=True, discrete_treatment=False, discrete_instrument=False)
            est2.fit(Y,T,Z=Z,X=X,W=W)
            est2.summary(alpha=0.05)
            het_results[0][2] = str(round(est2.coef_[0][0][0],2)) + addStars(est2.coef__inference().pvalue()[0][0][0])
            het_results[1][2] = round((est2.coef__interval()[1][0][0][0] - est2.coef__interval()[0][0][0][0])/3.92,2)
            het_results[2][2] = str(round(est2.intercept_[0][0],2)) + addStars(est2.intercept__inference().pvalue()[0][0])
            het_results[3][2] = round((est2.intercept__interval()[1][0][0] - est2.intercept__interval()[0][0][0])/3.92,2)

            est2.fit(Y_train, T_train, Z=Z_train, X=X_train, W=W_train)
            te_2 = est2.effect(X_train)
            te_2_lb, te_2_ub = est2.effect_interval(X_train, alpha=0.05)
            te_pred2 = est2.effect(X_test)
            te_pred2_lb, te_pred2_ub = est2.effect_interval(X_test, alpha=0.05)

            # #  DMLIV Estimator
            # est3 = DMLIV(
            #     discrete_treatment=False,
            #     discrete_instrument=False,
            # )
            # est3.fit(Y, T, Z=Z, X=X, W=W, inference='bootstrap')
            # het_results[0][3] = est3.const_marginal_effect(X)[0][0]
            # het_results[1][3] = (est3.const_marginal_effect_interval(X)[1][0][0] - est3.const_marginal_effect_interval(X)[0][0][0])/3.92
            # het_results[2][3] = est3.intercept_[0][0]
            # het_results[3][3] = (est3.intercept__interval()[1][0][0] - est3.intercept__interval()[0][0][0])/3.92

    
            # # Linear DRIV Estimator
            # est4 = LinearDRIV(discrete_treatment=False, discrete_instrument=False)
            # est4.fit(Y, T, Z=Z, X=X, W=W)
            # het_results[0][4] = est4.const_marginal_effect(X)[0][0]
            # het_results[1][4] = (est4.const_marginal_effect_interval(X)[1][0][0] - est4.const_marginal_effect_interval(X)[0][0][0])/3.92
            # het_results[2][4] = est4.intercept_[0][0]
            # het_results[3][4] = (est4.intercept__interval()[1][0][0] - est4.intercept__interval()[0][0][0])/3.92
            
            het_table = tabulate(het_results, het_headers, tablefmt='latex_booktabs')
            # Write the LaTeX code to a file
            with open(TABS+'/ml/het_results_'+str(pc)+'_GM_'+inst+'_'+ex+'.tex', 'w') as f:
                f.write(r"\begin{table}\centering\caption{"+instlab+" instrument, "+pclab+"}")
                f.write(het_table)
                f.write(r"\end{table}")

            
            
            plt.plot(X_test[:, 0], te_pred1, label='Test Values', alpha=0.6, color = 'red')
            plt.fill_between(X_test[:, 0], te_pred1_lb[:,0], te_pred1_ub[:,0], alpha=0.4, color = 'red')
            plt.plot(X_train[:, 0], te_1, label='Trained Values', alpha=0.6, color = 'blue')
            plt.fill_between(X_train[:, 0], te_1_lb[:,0], te_1_ub[:,0], alpha=0.4, color = 'blue')
            plt.xlabel("X[0]")
            plt.ylabel("Treatment Effect")
            plt.legend()
            plt.title("Ortho-IV")
            plt.show()
            
            plt.plot(X_test[:, 0], te_pred2, label='Test Values', alpha=0.6, color = 'red')
            plt.fill_between(X_test[:, 0], te_pred2_lb[:,0], te_pred2_ub[:,0], alpha=0.4, color = 'red')
            plt.plot(X_train[:, 0], te_2, label='Trained Values', alpha=0.6, color = 'blue')
            plt.fill_between(X_train[:, 0], te_2_lb[:,0], te_2_ub[:,0], alpha=0.4, color = 'blue')
            plt.xlabel("X[0]")
            plt.ylabel("Treatment Effect")
            plt.legend()
            plt.title("Projected Ortho-IV")
            plt.show()
           


        