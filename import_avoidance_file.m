function data = import_avoidance_file(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [STIMULUS_NR,ACTIVE,FLIPPED,CSONSET,DECISIONONSET,RESPONSE,RT,REINFORCED,CHOICE,IMAGE]
%   = IMPORTFILE(FILENAME) Reads data from text file FILENAME for the
%   default selection.
%
%   [STIMULUS_NR,ACTIVE,FLIPPED,CSONSET,DECISIONONSET,RESPONSE,RT,REINFORCED,CHOICE,IMAGE]
%   = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW
%   through ENDROW of text file FILENAME.
%
% Example:
%   [Stimulus_Nr,Active,Flipped,CSOnset,DecisionOnset,Response,RT,Reinforced,Choice,Image] = importfile('hybrid_task_avoidance_18.txt',4, 135);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2017/06/18 13:48:46

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 4;
    endRow = inf;
end

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,8,10]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,2,3,4,5,6,8,10]);
rawCellColumns = raw(:, [7,9]);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Allocate imported array to column variable names
Stimulus_Nr = cell2mat(rawNumericColumns(:, 1));
Active = cell2mat(rawNumericColumns(:, 2));
Flipped = cell2mat(rawNumericColumns(:, 3));
CSOnset = cell2mat(rawNumericColumns(:, 4));
DecisionOnset = cell2mat(rawNumericColumns(:, 5));
Response = cell2mat(rawNumericColumns(:, 6));
RT = rawCellColumns(:, 1);
Reinforced = cell2mat(rawNumericColumns(:, 7));
Choice = rawCellColumns(:, 2);
Image = cell2mat(rawNumericColumns(:, 8));
choseCircle=strcmp('circle',Choice);
RT=str2double(RT);

data =[Stimulus_Nr,Active,Flipped,CSOnset,DecisionOnset,Response,RT,Reinforced,choseCircle,Image];
data = data(~isnan(Active),:);
