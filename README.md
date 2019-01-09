# Equity-Statistical-Arbitrage
Under the similar economic background, equities share the risk exposures, so they share the similar price movement. The equity price movements can be decomposed to major risk exposure, idiosyncratic risk and a slow price drift. We can assume idiosyncratic risk is mean-reverting and estimate the risk exposure of bundles of equities by principal components. If the difference between the theoretical price and real equity price exists, there will be some opportunities to arbitrage. 
##I.  Specification 
###A.	Universe
The strategy analyzes the performance of equity statistical arbitrage in U.S. stock market. We collected totally 482 stocks which are existed between 1/1/2006 and 12/31/2013 from 8 different industries including utilities, healthcare, services, industrial goods, basic materials, consumer goods, technology and finance. We want the data to be sufficiently and comprehensive to support our strategy implementation. However, the survivorship biased exists in the data selection.  
###B.	Date Range
The data range is between 1/1/2006 and 12/31/2013. We think 8 years is a suitable period to implement our strategy. The data range includes the 2008 financial crisis which means we can analyze the strategy performance during the financial crisis. We can perform some risk management analysis such as VaR. Also, it is easy for us to check the correlation between the market and strategy during the market crash. We used 400 stocks for the principle components analysis. 25 target stocks are used for in-sample, while 15 stocks are used for out-of -sample. 
###C.	Data Sources
The data is downloaded from Yahoo finance, since Yahoo finance is an authoritative, accurate and accessible financial source website.
###D.	Signal Generation
Computing the Signal 
	Analyze market with PCA to design risk bundles 
∑_(j=1)^N▒〖β_ij R_j 〗
	Regress the target returns against the risk bundles
R_n^S=β_0+βR_n+ε_n   ,n=1,2,…,60
	Analyze the residuals as an AR(1) process. Estimate the a, b, Var (ζ) below.
X_(n+1)=φX_n+ζ_(n+1),n=1,2,…,59
	Extract the walk parameters and observe the signal. Note that m bar below is the average position of m across many stocks.
σ ̂=√(Variance(ζ))m = β_0+βR_n,s=(X_60-m)/σ ̂ 
	Trading the signal: Use the mean reversion of the idiosyncratic risk to sell short when s is high and go long when s is low.
###E.	Portfolio Construction
The portfolio is equally weighted for all target stocks. (25 target stocks for backtest; only the mean performance of the 25 are cared about) For each stock, we repeated the process given below:
1)	Representing the stocks return data on given dates and going back M+1 days as a matrix
2)	Identify principle components; Adopt principle components covering 55% variance
3)	Generate signal, according to steps in Part D
4)	Go into long/short position according to the sign of signal: Long target stock short principle components or Long principle components short target stock with adjusted coefficient.
##II.  Implementation  
1)	Sensibility
The strategy is based on the assumption that a set of statistical relationships, co-intergrations, will revert to their historical means. A drift from a historical relationship implies the market did not price a specific asset with a specific factor change, hence an arbitrage opportunity exists.
2)	Efficacy
The strategy was lost in around 2008. 2009 the rate of return has risen rapidly and maintained at a certain level. From Plot-1, the strategy get the higher cumulative return during 2006-2007 and 2012-2013. The rate of cumulative return continues to oscillate over the past 2008 to 2010 years.  That is to say, ignoring the impact of the financial crisis, the cumulative yield of the strategy is good. This is also reflected in Plot-3.
From Plot-2 we can see that the estimated variance of residuals increased a lot after 2008 which could be suggested by financial crisis. With the big variance of residual and small number of principal components, the performance should be better than other times suggested by common papers. While in our implementation, in the period of 2008-2009, we do see a small return from previous downtrend, but that’s far from our expectation.
3)	Adjustments
a)	Trigger values for open / close positions are adjusted according to signals.
b)	Minimum 5 Principal Components are guaranteed.
4)	Costs
We ignored the Transaction costs in back-test. It will be considered in refinement. 
Also, financing costs and other execution costs are ignored in our strategy. 
##III.  Refinements 
1)	Transaction Costs
In the first implementation backtest, we didn’t consider the transaction costs. Actually, transaction costs  occur every time we open a new position (i.e. when we short our target stocks or short those principal components stocks). To make our model more realistic, we add a fixed proportion of transaction costs to our strategy.

2)	Time Series Modeling
The paper chose AR (1) model to get the coefficient and variance of the model to calculate the signal. However, sometimes the AR (1) may not have a good prediction power, that is, there may be some other time series model that fits our return data better. To avoid the bias that may be caused by a poor-fitted model, we directly extract the sample autocovariance at lag 0 (h = 0) to calculate the signal.

3)	Weighting Method
For the first implementation and backtest, we used equally weighting to construct our portfolio. For those traditional portfolio construction processes, we usually consider putting higher weight on those stocks that have some better metrics than others, such as higher momentum and better earnings record. However, here the way we make money is way different to those traditional ones: we are trying to seize the inequality between the theoretical return and the actual return of our target stocks through the regression on PCA and make profit by either longing or shorting our target stocks, which means there’s actually not any significant relationship between the recent performance of stocks and the return of our strategy. Hence, we decide not to keep using equally weighting.  

4)	PCA/Regression Frequency
For this strategy, PCA and regression are combined to build model and calculate the trading signal. We redo the PCA every 180 days if there’s no position enrolled. However, we don’t know exactly how long one PCA model can hold to be effective and can keep explaining enough variance of our model. For the future research, improvements related to this part may be added to the strategy to ensure the effectiveness of our PCA model.
