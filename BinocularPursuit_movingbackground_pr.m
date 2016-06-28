% function DotCoherent
% behaviour experiment using coherent moving dots, which is used in a fMRI study
% Authtor: Bo Cloud Cao, 08/06/2013
% Email:   ffcloud.tsao@gmail.com
% Modified from:
% dot motion demo using SCREEN('DrawDots') subfunction
% author: Keith Schneider, 12/13/04
% function DichopticPursuit_Mono_EL

clear

AssertOpenGL;

%Screen('Preference', 'SkipSyncTests',1);       % Skip synchronization test. Use on your own risk
%based on Cloud experience, this can facilitate the program run at least.

try
    
    %% Important parameters
    % define moition vector
    theta_motion_vector = [0, pi];
    % dummy mode or not; 0 by default; if set to 1, will use mouse instead
    % of eye tracker
    dummymode= 0;
    % speed of target
    target_speed   = 10;    % target speed (deg/sec)
    % speed of dots
    dot_speed   =    8;    % dot speed (deg/sec)
    % total trial number
    total_trial_number = 20;
    
    % Added a dialog box to set your own EDF file name before opening
    % experiment graphics. Make sure the entered EDF file name is 1 to 8
    % characters in length and only numbers or letters are allowed.
    if IsOctave
        edfFile = 'DEMO';
    else
        prompt = {'Enter tracker EDF file name (1 to 8 letters or numbers)'};
        dlg_title = 'Create EDF file';
        num_lines= 1;
        def     = {'DEMO'};
        answer  = inputdlg(prompt,dlg_title,num_lines,def);
        edfFile = answer{1};
        fprintf('EDFFile: %s\n', edfFile );
    end
    
    %%
    
    % ------------------------
    % set dot field parameters
    % ------------------------
    
    %   Set keys.
    KbName('UnifyKeyNames');
    rightKey = KbName('RightArrow');
    leftKey = KbName('LeftArrow');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    space = KbName('space');
    escapeKey = KbName('ESCAPE');
    stopkey = KbName('Q');
    
    time_total = 10;     % second
    time_target_appear = 2;     % second
    trial = cell(total_trial_number,1);
    
    random_index = randperm(total_trial_number);
    sign_vector = [ones(1,total_trial_number/2),-ones(1,total_trial_number/2)];
    %     task_druation = 3;   % second
    %     motion_duration = 5; % duration for each direction of motion, second
    %     time_changedirection = motion_duration:motion_duration:time_total;
    %     time_task = (0:task_druation:time_total-task_druation) +  rand(1, time_total/task_druation);
    
    
    % define colors
    Red = [128,0,0];
    Green = [0,128,0];
    Blue = [0,0,255];
    Gray = [128,128,128];
    color_set = [Red; Green; Blue; Gray];  % The set of colors used in changing the color of the fixation
    
    
    
    %define visual stimulus parameters
    
    mon_width   = 145.8;   % horizontal dimension of viewable screen (cm)
    v_dist      = 166.4;   % viewing distance (cm); changed from 54.6 cm, 39.4cm
    % changed from 47.3 cm and 39 cm
    
    target_distance = 20;  % initial target distance to fixtation (degree)
    
    ndots       = 300; % number of dots, re-refined after xy in the initialization section
    max_d       = 10;   % maximum radius of  annulus (degrees)
    min_d       = 0;    % minumum
    dot_w       = 0.2;  % width of dot (deg)
    target_w       = 0.5;  % width of target (deg)
    target_color = Green; % color of target
    fix_r       = 0.25; % radius of fixation point (deg)
    fix_thickness = 0.05; % thickness of fixation crossing (deg)
    f_kill      = 0.00; % fraction of dots to kill each frame (limited lifetime)
    differentcolors =0; % Use a different color for each point if == 1. Use common color white if == 0.
    differentsizes = 0; % Use different sizes for each point if >= 1. Use one common size if == 0.
    waitframes = 1;     % Show new dot-images at each waitframes'th monitor refresh.
    
    if differentsizes>0  % drawing large dots is a bit slower
        ndots=round(ndots/5);
    end
    
    % ---------------
    % open the screen
    % ---------------
    
    doublebuffer=1;
    screens=Screen('Screens');
    screenNumber=max(screens);
    % [w, rect] = Screen('OpenWindow', screenNumber, 0,[1,1,801,601],[], doublebuffer+1);
    [w, rect] = Screen('OpenWindow', screenNumber, 0,[], 32, doublebuffer+1);
    el=EyelinkInitDefaults(w);
    
    % Enable alpha blending with proper blend-function. We need it
    % for drawing of smoothed points:
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [center(1), center(2)] = RectCenter(rect);
    Width = rect(3)-rect(1);
    Height = rect(4)-rect(2);
    fps=Screen('FrameRate',w);      % frames per second
    ifi=Screen('GetFlipInterval', w);
    if fps==0
        fps=1/ifi;
    end;
    
    Black = BlackIndex(w);
    White = WhiteIndex(w);
    
    nframes     = time_total * fps; % number of animation frames in loop
    
    % ---------------------------------------
    % initialize dot positions and velocities
    % ---------------------------------------
    
    ppd = pi * (Width) / atan(mon_width/v_dist/2) / 360;    % pixels per degree
    target_pfs = target_speed * ppd / fps;                  % target speed (pixels/frame)
    pfs = dot_speed * ppd / fps;                            % dot speed (pixels/frame)
    s = dot_w * ppd;                                        % dot size (pixels)
    target_size = target_w * ppd;                           % target size (pixels)
    fixation_center = [center(1), center(2)];
    %     fix_cord = [fixation_center(1)-fix_r*ppd, fixation_center(2)-fix_thickness/2*ppd, fixation_center(1)+fix_r*ppd, fixation_center(2)+fix_thickness/2*ppd;
    %                 fixation_center(1)-fix_thickness/2*ppd, fixation_center(2)-fix_r*ppd, fixation_center(1)+fix_thickness/2*ppd, fixation_center(2)+fix_r*ppd];
    fix_cord = [fixation_center-fix_r*ppd, fixation_center+fix_r*ppd];
    
    [x,y] = find(rand(Width, Height)>0.995);   % dot positions in Cartesian coordinates (pixels from center)
    ndots = size(x,1);
    xy = [x, y] - ones(ndots, 1) * center;
    
    % Create a vector with different colors for each single dot, if
    % requested:
    if (differentcolors==1)
        colvect = uint8(round(rand(3,ndots)*255));
    else
        colvect=White;
    end;
    
    % Create a vector with different point sizes for each single dot, if
    % requested:
    if (differentsizes>0)
        s=(1+rand(1, ndots)*(differentsizes-1))*s;
    end;
    
    trial_number = 1;
    buttons=0;
    fixation = 1;                   % fixation on
    time = 0;                       % initialize time
    index_changedirection = 1;      % initialize the index of time_changedirection
    log_motion =[];                 % initialize motion log, which will record the direction change and the time of the change
    index_task = 0;                 % initialize the index of time_task
    log_task =double([]);           % initialize motion log, which will record the response and the time of the color change of the fixation point
    response_index = 1;             % initialize the response index, which is used to prevent redundant recordings
    total_distance = zeros(ndots,1); % initialize the total distance that each dot travels
    RF_size = 0.5;                  % RF size at 1 degree eccentricity
    max_total_distance = 100;     % initialize the total distance that each dot travels maximumly
    fixation_color = White;       % initialize the fixation color
    target_movingdistance = 0;
    log = 0;
    
    EyelinkUpdateDefaults(el);
    
    % Initialize Eye link
    if ~EyelinkInit(dummymode, 1)
        fprintf('Eyelink Init aborted.\n');
        Eyelink('Shutdown');sca;  % cleanup function
        return;
    end
    
    % open file to record data to
    res = Eyelink('Openfile', edfFile);
    if res~=0
        fprintf('Cannot create EDF file ''%s'' ', edffilename);
        cleanup;
        return;
    end
    
    % make sure we're still connected.
    if Eyelink('IsConnected')~=1 && ~dummymode
        cleanup;
        return;
    end
    
    HideCursor;	% Hide the mouse cursor
    
    
    %Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    
    %========================
    % SET UP TRACKER CONFIGURATION
    % Setting the proper recording resolution, proper calibration type,
    % as well as the data file content;
    Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox demo-experiment''');
    
    % This command is crucial to map the gaze positions from the tracker to
    % screen pixel positions to determine fixation
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, Width-1, Height-1);
    
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, Width-1, Height-1);
    
    % set calibration type.
    %     Eyelink('command', 'calibration_type = HV9');
    %     Eyelink('command', 'generate_default_targets = YES');
    
    % set parser (conservative saccade thresholds)
    %     Eyelink('command', 'saccade_velocity_threshold = 35');
    %     Eyelink('command', 'saccade_acceleration_threshold = 9500');
    
    
    % 5.1 retrieve tracker version and tracker software version
    [v,vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    vsn = regexp(vs,'\d','match');
    
    % set EDF file contents. Note the FIXUPDATE event for fixation update
    if v ==3 && str2double(vsn{1}) == 4 % if EL 1000 and tracker version 4.xx
        % remote mode possible add HTARGET ( head target)
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        % set link data (used for gaze cursor)
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT,FIXUPDATE');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT,HTARGET');
    else
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT,FIXUPDATE');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
        % set link data (used for gaze cursor)
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT,FIXUPDATE ');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
    end
    %________________________
    
    
    
    %lock both eye so the tracker would not reselect the better eye after
    %validation
    Eyelink('command', 'select_eye_after_validation = NO');
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    %     % do a final check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);
    
    
    %     % Check both eye are being tracked
    %     evt = Eyelink( 'NewestFloatSample');
    %     eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
    %     if eye_used ~= el.BINOCULAR; % if both eyes are tracked
    %         fprintf('Both eyes need to be tracked.\n');
    %         Eyelink('Shutdown');sca;  % cleanup function
    %         return;
    %     end
    %% Initial flip
    Screen('FillRect', w, Gray)
    HideCursor;	% Hide the mouse cursor
    Priority(MaxPriority(w));
    pause(1)
    
    % Do initial flip...
    vbl=Screen('Flip', w);
    
    %% Instructions
    while 1
        [ keyIsDown, seconds, keyCode ] = KbCheck;
        
        if keyCode(escapeKey)
            Screen('CloseAll');
            return;
        elseif keyCode(space)
            break;
        end
        
        DrawFormattedText(w, 'Instructions \n \n  Please fixate at the center white dot whenever it is presented. \n \n As soon as the moving red dot hits the white dot \n \n Track the red dot with your eyes as precisely as possible. \n \n Click space to proceed.', 'center', 'center');
        Screen('Flip', w);
    end
    %% Experiment
    % --------------
    % animation loop
    % --------------
    
    for trial_number = 1:total_trial_number
        Eyelink('Message', 'TRIALID %d', trial_number);
        % Before recording, we place reference graphics on the host display
        % Must be in offline mode to transfer image to Host PC
        Eyelink('Command', 'set_idle_mode');
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        
        stimuluson = 0;
        movingtargetON = 0;
            
        time=0;
    
        trial{trial_number}.EL_time = [];
        trial{trial_number}.EL_target_x = [];
        trial{trial_number}.EL_target_y = [];
        trial{trial_number}.EL_LEFT_x = [];
        trial{trial_number}.EL_LEFT_y = [];
        trial{trial_number}.EL_RIGHT_x = [];
        trial{trial_number}.EL_RIGHT_y = [];
        trial{trial_number}.EL_pursuit = [];  % status of Ifpursuit at the sample rate
        trial{trial_number}.target_speed = target_speed;
        trial{trial_number}.dot_speed = dot_speed;
        trial{trial_number}.fixation_x = fixation_center(1);
        trial{trial_number}.fixation_y = fixation_center(2);
        Ifpursuit = 0;    % indicate if pursuit has started, 0, not started, 1 started.
        
        trial{trial_number}.NextDataType = [];
        
        
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.05);
        
        EyelinkDoDriftCorrection(el);
        Eyelink('StartRecording');
        Eyelink('Message', 'SYNCTIME');
        
        % ==========
        % Check both eye are being tracked
        evt = Eyelink( 'NewestFloatSample');
        eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
        if eye_used ~= el.BINOCULAR; % if both eyes are tracked
            fprintf('Both eyes need to be tracked.\n');
            Eyelink('Shutdown');sca;  % cleanup function
            return;
        end
        tic;
        
        fixation = 1;                   % fixation on
        theta_motion = theta_motion_vector(mod(random_index(trial_number),size(theta_motion_vector,2)) +1);                        % motion direction in [0 2*pi)
        trial{trial_number}.theta_motion = theta_motion;
        dxdy = sign_vector(random_index(trial_number)) * ones(ndots,1) * pfs * [cos(theta_motion), sin(theta_motion)]; % change in x and y per frame (pixels)
        
        xy_target_center = center - target_distance * ppd * [cos(theta_motion), sin(theta_motion)]; % target center location in pixels
        target_start_location = xy_target_center ;
        xy_target = [xy_target_center - target_size/2, xy_target_center + target_size/2]; % target center location in pixels
        xy_targetdestination = -target_distance * ppd * [cos(theta_motion), sin(theta_motion)]; % target location in pixels
        dxdy_target = target_pfs * [cos(theta_motion), sin(theta_motion)]; % change in x and y of target per frame (pixels)
        
        trial{trial_number}.target_speed = cos(theta_motion) * target_speed;
        trial{trial_number}.dot_speed = sign_vector(random_index(trial_number)) * cos(theta_motion) * dot_speed;
        trial{trial_number}.relative_target_speed = trial{trial_number}.target_speed - trial{trial_number}.dot_speed;
        trial{trial_number}.target_faster = abs(trial{trial_number}.relative_target_speed) > abs(trial{trial_number}.target_speed);
        count = 0;
        count2 = 0;
        while abs(xy_target_center(1) - center(1)) < Width/2 && abs(xy_target_center(2) - center(2) ) < Width/2
            
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
            
            %time = time + ifi * (frame - initial_frame);
            time =toc; % here in the Skype with Cloud, we updated the time based on toc-- see the tic.
            
            
            % If Escape Key is pressed, terminate the trial
            [ keyIsDown, seconds, keyCode ] = KbCheck;
            if keyCode(escapeKey)
                Eyelink('Shutdown');sca;
            end
            
            % Show static image before target appears
            if (time < time_target_appear) && fixation
                Screen('DrawDots', w, xy', s, Green, center,1);  % change 1 to 0 to draw square dots
                Screen('FillOval', w, fixation_color, fix_cord');	% draw fixation dot (flip erases it)
                if (doublebuffer==1)
                    vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
                end;
            end;
            
            if stimuluson == 0
                Eyelink('Message','stimulus starts');
                stimuluson = 1;
            end
            
            
            % Show static background and moving target before target reaches
            % fixtion
            if (time >= time_target_appear) && fixation
                Screen('DrawDots', w, xy', s, Green, center,1);  % change 1 to 0 to draw square dots
                Screen('FillOval', w, target_color, xy_target');	% draw target (flip erases it)
                Screen('FillOval', w, fixation_color, fix_cord');	% draw fixation dot (flip erases it)
                
                if (doublebuffer==1)
                    vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
                end;
                
                if movingtargetON == 0
                    Eyelink('Message','moving target starts')
                    movingtargetON = 1;
                end

                xy_target = xy_target + [dxdy_target, dxdy_target];    % move target
                xy_target_center = xy_target_center + dxdy_target;
                target_movingdistance = target_movingdistance +  target_speed / fps;
                count = count +1;
                
                % every time that target position was updated and screen
                % flip, put the msg in edf file
                Eyelink('Message', 'TargetLoc: %d %d ', round(xy_target_center(1)), round(xy_target_center(2)));
                
                
                if dot(xy_target_center - fixation_center, target_start_location - fixation_center) <= 0
                    fixation =0;
                end
            end
            
            if Eyelink( 'NewFloatSampleAvailable') > 0
                % get the sample in the form of an event structure
                evt = Eyelink( 'NewestFloatSample');
                trial{trial_number}.EL_time = [trial{trial_number}.EL_time, toc];
                trial{trial_number}.EL_target_x = [trial{trial_number}.EL_target_x, xy_target_center(1)];
                trial{trial_number}.EL_target_y = [trial{trial_number}.EL_target_y, xy_target_center(2)];
                trial{trial_number}.EL_LEFT_x = [trial{trial_number}.EL_LEFT_x, evt.gx(1)];  % 1 for left eye, 2 for right eye
                trial{trial_number}.EL_LEFT_y = [trial{trial_number}.EL_LEFT_y, evt.gy(1)];
                trial{trial_number}.EL_RIGHT_x = [trial{trial_number}.EL_RIGHT_x, evt.gx(2)];  % 1 for left eye, 2 for right eye
                trial{trial_number}.EL_RIGHT_y = [trial{trial_number}.EL_RIGHT_y, evt.gy(2)];
                trial{trial_number}.EL_pursuit = [trial{trial_number}.EL_pursuit, Ifpursuit];
                
                type = Eyelink('GetNextDataType');
                [evtstr] = geteventtype(el, type);
                trial{trial_number}.NextDataType = [trial{trial_number}.NextDataType, {evtstr}];
                
                
            end % if sample available
            
            % Show moving background and moving target after target reaches
            % fixtion
            if (time >= time_target_appear) && fixation ==0
                if Ifpursuit ==0
                    Eyelink('Message', 'pursuit start time');
                end
                
                Ifpursuit = 1;
                Screen('DrawDots', w, xy', s, Green, center,1);  % change 1 to 0 to draw square dots
                Screen('FillOval', w, target_color, xy_target');	% draw target (flip erases it)
                
                if (doublebuffer==1)
                    vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
                end;
                
                xy_target = xy_target + [dxdy_target, dxdy_target];                    % move target
                xy_target_center = xy_target_center + dxdy_target;
                count2 = count2 +1;
                
                target_movingdistance = target_movingdistance +  target_speed / fps;
                xy = xy + dxdy;						                    % move dots
                xy = mod(xy + ones(ndots,1) * center, ones(ndots,1) * [Width, Height]) - ones(ndots,1) * center; % replace dots moving out of the window
            
                % every time that target position was updated and screen
                % flip, put the msg in edf file
                Eyelink('Message', 'TargetLoc: %d %d ', round(xy_target_center(1)), round(xy_target_center(2)));
            end
            

            
            
            if Eyelink( 'NewFloatSampleAvailable') > 0
                % get the sample in the form of an event structure
                evt = Eyelink( 'NewestFloatSample');
                trial{trial_number}.EL_time = [trial{trial_number}.EL_time, toc];
                trial{trial_number}.EL_target_x = [trial{trial_number}.EL_target_x, xy_target_center(1)];
                trial{trial_number}.EL_target_y = [trial{trial_number}.EL_target_y, xy_target_center(2)];
                trial{trial_number}.EL_LEFT_x = [trial{trial_number}.EL_LEFT_x, evt.gx(1)];  % 1 for left eye, 2 for right eye
                trial{trial_number}.EL_LEFT_y = [trial{trial_number}.EL_LEFT_y, evt.gy(1)];
                trial{trial_number}.EL_RIGHT_x = [trial{trial_number}.EL_RIGHT_x, evt.gx(2)];  % 1 for left eye, 2 for right eye
                trial{trial_number}.EL_RIGHT_y = [trial{trial_number}.EL_RIGHT_y, evt.gy(2)];
                trial{trial_number}.EL_pursuit = [trial{trial_number}.EL_pursuit, Ifpursuit];
                trial{trial_number}.evt = evt;
                
                type = Eyelink('GetNextDataType');
                [evtstr] = geteventtype(el, type);
                trial{trial_number}.NextDataType = [trial{trial_number}.NextDataType, {evtstr}];
                
                
            end % if sample available
        end
        %         duration = time;
        %         fprintf('itrial = %d, duration = %f\n', trial_number, duration);
        %         fprintf('count = %d',count);
        %         fprintf('count2 = %d',count2);
        
        
        Eyelink('Message', 'stimulus ends');
        Eyelink('StopRecording');
        
        DrawFormattedText(w, 'Did the target move faster or slower after it reached the white dot? \n \n  UP arrow if the target moved FASTER \n DOWN arrow if the target moved SLOWER', 'center', 'center');
        Screen('Flip',w);
        [ seconds, keyCode, deltaSecs] = KbWait;
        if keyCode(escapeKey)
            Eyelink('Shutdown');sca;
        elseif keyCode(upKey)
            trial{trial_number}.response_faster = 1;
            resp = 'fast';
        elseif keyCode(downKey)
            trial{trial_number}.response_faster = 0;
            resp = 'slow';
        end
        
        Eyelink('Message', 'resp =  %s', resp);
        Eyelink('Message', 'Target eye = none');    
        Eyelink('Message', 'TRIAL_RESULT 0');
        
    end
    
    % End of Experiment; close the file first
    % close graphics window, close data file and shut down tracker
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    
    DrawFormattedText(w, 'Session ends \n \nTake a break \n ', 'center', 'center');
    Screen('Flip',w);
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end
    
    
    save(['BinocularPursuit_MovingB_',datestr(now,30)])
    Priority(0);
    ShowCursor
    Eyelink('Shutdown');sca;
catch ME
    %by having try, in case something goes wrong, catch will catch it and run the following lines.
    %     save(['BinocularPursuit_Error_',datestr(now,30)])
    ME.message
    ME.stack.line
    Priority(0);
    ShowCursor
    Eyelink('Shutdown');
    sca;
end

% Cleanup routine:
% function cleanup
% % Shutdown Eyelink:
% Eyelink('Shutdown');
%
% % Close window:
% sca;
%
% % Restore keyboard output to Matlab:
% ListenChar(0);
