% Fits Q-learning model to each subject's choices in the Probabilistic Learning Task
% Update stimulus-response associations for 2 stimuli and 2 responses each
% Q value of response 1 on trial 20 is indicated as Q(1,20)

% Estimates learning rate (alpha) and softmax/exploration (beta) parameter per subject
% Use same parameters for all stimuli

function output = QLearning_PAL(curdat)


% --- create multistart object
ms = MultiStart; % A multi-start global optimization solver.

% --- create problem structure
%  learning rate & Softmax start values. Other start valus will also be used, see below.
start_params = [0.5 .5 .5];
OPTIONS = optimset('Algorithm','sqp','TolFun',1e-12,'TolCon',1e-12,'display','off');%turn display 'iter' if want to see output
lb = [0 0 0];%Vector of lower bounds.
ub = [1 100 1]; %[1 100 1]; %Vector of upper bounds.

problem = createOptimProblem('fmincon','x0',start_params, ...
    'objective', @model_fit,'lb',lb,'ub',ub, 'options',OPTIONS);

% --- set # random start points, now used 20
[xmin,fmin,flag,outpt,allmins] = run(ms,problem,20);

% --- put best fitting parameters in output (needed to compute trial-by-trial PEs, Q-values, etc.)
output.alpha = xmin(1);
output.beta = xmin(2);
output.gamma = xmin(3);
output.negloglik = fmin;

% --- MLE estimation for model

    function minimizeloglik = model_fit(arg)
        
        % read data into a cell array D, NaNs become 0's (for choices)
%         [dat, txt]=xlsread(['C:\Users\pak5_000\Desktop\hybrid_conditioning\hybrid_data\hybrid_task_avoidance_' num2str(subj) '.xlsx']);
%         dat=dat(~isnan(dat(:,1)),:);
%         choice={txt{5:28,9} txt{33:56,9} txt{61:84,9} txt{89:112,9}};
%         resp = double(strcmp(choice,'circle'))+1; %chose circle 1, triangle 2
%         A=dat(:,2); %active trial
% %         resp(~A)=NaN;
%         Ntrials = length(resp);
        pain = -curdat(:,1); %-1 negative 0 neutral 
        resp = curdat(:,2); %chose circle = 1, triangle = 2
        Ntrials = length(resp);
  
        for i = 1:Ntrials  % trial-by-trial updating of stim-resp associations
%             display(i)
            % set Q values at start of each list to .5 for all stim-resp associations
            for r = 1:2
                Q(r,1) = -.5; % for the first trial, initialize the q value as .5
            end
            
            % --- softmax rule
            % numerator softmax, arg(1)= softmax-temp/beta (higher = more random)
            for r = 1:2
                ns(r,i) = exp(Q(r,i)/arg(2));
            end
            
            % denominator softmax
            ds(i) = sum(ns(:,i));
            
            % softmax equation; Prob(r,i) = probability resp r on trial i
            for r = 1:2
                Prob(r,i) = ns(r,i)/ds(i);
            end
            
            % --- stim-response association updating   arg(2) = LR/alpha
            % first copy all Q values to next trial, then update/overwrite only
            % those for the stimulus of the current trial
            
            Q(:,i+1)= Q(:,i); % initial q value for (i+1)th trial
            
            % for s = stim(i)
            % do not update Q values for trails with missing response or if
            % it is a passive trial
            PE(i) = pain(i) - Q(resp(i),i);
            
            if isnan(resp(i)) | curdat(i,3)==0 %comment this line out if want to update Q value for computer choice as well
                Q(:,i+1)= Q(:,i);
%                 PE(i)=nan;
            else
                if PE(i) >= 0
                    Q(resp(i),i+1) = Q(resp(i),i) + (arg(1) * PE(i) / arg(3)); %amplify pos PE
                else
                    Q(resp(i),i+1) = Q(resp(i),i) + (arg(1) * PE(i) * arg(3)); %discount neg PE
                end
                
                % MOD(i) = arg(3) * anx(i);
                % Q(resp(i),i+1) = Q(resp(i),i) + (arg(1)*MOD(i)*PE(i)); % chosen: updating
                Q(3-resp(i),i+1) = Q(3-resp(i),i); % unchosen: no updating
            end
            
            % --- model choice with softmax
            if resp(i) ~= 0;
                P(i) = ns(resp(i),i)/ds(i); %P = propability observed response
                logP(i) = log(P(i));                %log P
            end
            
        end
        
        loglik = sum(logP);        %sum of log probabilities
        minimizeloglik = -loglik;  %maximixe this (= minimize negative LL)
        
        output.Q = Q;
        output.PE = PE;
        output.logP = logP;
        
    end

end
