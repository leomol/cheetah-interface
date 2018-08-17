% Add dependencies to MATLAB path.
dependencies = {
        'MatlabImportExport_v6.0.0'
        'NetComDevelopmentPackage_v3.1.0\MATLAB_M-files'
    };
dependencies = fullfile(pwd, dependencies);
addpath(dependencies{:});