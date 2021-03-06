function [output] = LAPFI_train_n_estimateTest(dset, outpath, example_file, use_val)
% dset = LAPFI_attach_labels(dset);
% dset.set = dset.fold;
% if nargin>1 
%     dset = combine_datasets(LAPFI_attach_labels(dset), LAPFI_attach_labels(dset_test)); 
% end
% trainset = clean_dataset(dset, find(dset.set~=1));
% %trainset = clean_dataset(trainset, 1:5500);% temp
% output.train_KFSI_output = LAPFI_train_KFSI(trainset);
%output.train_KFSI_output = LAPFI_train_KFSI(clean_dataset(dset,find(dset.set~=1))); % this kinda worked
if ~isfield(dset,'set'), dset.set=dset.fold; end

if use_val
    dset.set(find(dset.set==2))=1;
    dset.fold=dset.set;
end
%disp('Validating model on training set..');
output.train_KFSI_output = LAPFI_train_KFSI(dset);
x=42;

%% Estimate test set:
disp('Generating test set predictions..');
predstruct = struct;
for li=1:5
    predstruct.labelnames{li} = output.train_KFSI_output.models{li}.labelname;
    param1 = output.train_KFSI_output.models{li}.kp;
    param2 = output.train_KFSI_output.models{li}.C;
    trains = find(dset.set==1);
    tests = find(dset.set==3);
    if li==1
        fprintf('Running kernel ELM on %d training, %d test instances.\n',numel(trains), numel(tests));
    end
    traindata = dset.data(trains,:);
    testdata = dset.data(tests,:);
    [traindata, output.norm_model, testdata] = fg_normalizeData(traindata, output.train_KFSI_output.models{li}.normtype, testdata, 0);
    trainkernel = ELM_kernel_matrix(traindata, output.train_KFSI_output.models{li}.kernel_type, param1);
    testkernel = ELM_kernel_matrix(traindata, output.train_KFSI_output.models{li}.kernel_type, param1, testdata); 
    [~, ~, ~, TestingAccuracy,Y,TY,~] = elm_kern(trainkernel', dset.labelset{li}(trains), testkernel', dset.labelset{li}(tests), 0, param2, 0);
    predstruct.predset{li} = TY';
    predstruct.pred_filename = dset.filename(tests);
end

output.pred = LAPFI_write_predictions_test(predstruct, outpath, example_file);

end % main function
