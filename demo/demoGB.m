function r = demoGB(test);

if notDefined('test'), test='patches'; end

switch test
case {'patches','grayPatches'}
	load('patchData_16x16.mat','whitendata','invpcatransf');
	args = {'type','GB', ...
			'eta',.005, ...
			'batchSz',25, ...
			'nEpoch',1000, ...
			'nHid',300, ...
			'sampleVis',0, ...
			'sparsity',0.03, ...
			'sparseFactor', 10, ...
			'displayEvery',1000, ...
			'varyEta', 100, ...
			'anneal', 1000, ...
			'visFun',@visRGBPatchLearning};

	clear r;  r = rbm(args,whitendata);
	r.auxVars.invXForm = single(invpcatransf); % FOR VISUALIZATION
	r = r.train;
	
case 'faces'
	fprintf('\nHere we train an RBM with Gaussian visible and Bernouilli')
	fprintf('\nhidden units on a dataset of grayscale face images.\n\n');
	%  load('gaussianData.mat');
	%------------------------------------------
	load('facesDataGray.mat');
	testIdx = randperm(size(data,1));
	trainIdx = testIdx(1:2300);
	testIdx(1:2300) = [];
	trainData = data(trainIdx,:);
	testData = data(testIdx,:);
	clear data

	% CENTER AND SCALE INPUT DATA
	trainData = bsxfun(@minus,trainData,mean(trainData));
	testData = bsxfun(@minus,testData,mean(testData));

	trainData = bsxfun(@rdivide,trainData,std(trainData));
	testData = bsxfun(@rdivide,testData,std(testData));

	args = {'type','GB', ...
			'eta',.001, ...
			'varyEta',9000, ...
			'anneal', 5000, ...
			'batchSz',100, ...
			'nEpoch',10000, ...
			'nHid',500, ...
			'sampleVis',1, ...
			'sparsity',0.03, ...
			'sparseFactor', 20, ...
			'wPenalty', 0.002, ...
			'visFun',@visPatchLearning};

	clear r;  r = rbm(args,trainData);r = r.train;

	nTest = 1;
	testData = randn(size(testData(1:nTest,:)));

	nIters = 1000;
	nSamples = 12;
	recon = r.sample(testData,nSamples,nIters);

	subplot(223);
	visWeights(testData');
	title('Random Initialization');

	subplot(224);
	visWeights(squeeze(recon));
	title(sprintf('%d Samples from Initialization',nSamples));

case {'class','classifier'}
	fprintf('\nHere we train an RBM Classifier on data sampled from a')
	fprintf('\n3-component Mixture of Gaussians Density Model.\n\n');
	load('gaussianData.mat');
	trainData = data; clear data;
	testData = testdata; clear testdata;
	%------------------------------------------

	args = {'type','GB', ...
			'eta',.01, ...
			'batchSz',64, ...
			'nEpoch',200, ...
			'nHid',100, ...
			'learnSigma2',1 ...
			'sampleVis',1, ...
			'sparse',0.0001, ...
			'visFun',@visGBClassLearn};

	clear r;  r = rbmClassifier(args,trainData,labels);r = r.train;

	% PREDICT CLASSES OF HOLD-OUT SET
	[pred,classError,misClass]=r.predict(testData,testlabels);

	figure(3);
	myScatter(testData,[],[],testlabels);
	hold on;
	myScatter(testData(misClass,:));
	title(sprintf('Missclassifications outlined (rate = %1.2f%%)',100*classError));
end