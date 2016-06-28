
AssertOpenGL;

showSprites = [];

waitframes = [];

if isempty(showSprites)
    showSprites = 0;
end

if isempty(waitframes)
    waitframes = 1;
end

try

    % ------------------------
    % set dot field parameters
    % ------------------------

    nframes     = 3600; % number of animation frames in loop
    % ---------------
    % open the screen
    % ---------------

    screens=Screen('Screens');
	screenNumber=max(screens);
    [w, rect] = Screen('OpenWindow', screenNumber, 0);
    Screen('Preference', 'ConserveVRAM', 4096);

    % Enable alpha blending with proper blend-function. We need it
    % for drawing of smoothed points:
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [center(1), center(2)] = RectCenter(rect)
	 fps=Screen('FrameRate',w);      % frames per second
    ifi=Screen('GetFlipInterval', w);
    if fps==0
       fps=1/ifi;
    end;
    
    white = WhiteIndex(w);

    Priority(MaxPriority(w));
    
    % Do initial flip...
    vbl=Screen('Flip', w);
    
    % ---------------------------------------
    % initialize dot positions and velocities
    % ---------------------------------------
    
    disp('RECT HEIGHT')
    disp(RectHeight(rect))
    disp('RECT WIDTH')
    disp(RectWidth(rect))
    
    rect_h = RectHeight(rect);
    rect_w = RectWidth(rect);
    
    hdist = rect_h;
    wdist = rect_w;
   
    time_to_start = 20;
   start_time = GetSecs;
   while(GetSecs - start_time < time_to_start)
        DrawFormattedText(w, 'INSTRUCTIONS', 'center', 390, white);
        DrawFormattedText(w, 'You will now participate in a test designed to examine your visual preferences', 'center', 440, white);
        DrawFormattedText(w, 'In this exercise, two videos will be displayed side by side', 'center', 470, white);
        DrawFormattedText(w, 'Simply look around at the screen where you please', 'center', 500, white);
        DrawFormattedText(w, 'There are no further instructions', 'center', 530, white);
        DrawFormattedText(w, ['The test will begin in ' num2str(round(time_to_start-(GetSecs-start_time))) ' seconds'] , 'center', 580, white);
        DrawFormattedText(w, '(or press any key to skip)' , 'center', 610, white);
        Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
        % get key/mouse press to skip introduction screen
        [mx, my, buttons]=GetMouse(screenNumber);
        if any(buttons)
            break;
        end
        n ='YOYOYO'
        if KbCheck
            break;
        end;
        
        vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
   end
   n = 'yo'
   
   Screen(w,'FillRect', [0 0 0]);
   vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
   WaitSecs(1);
    
   moviename = [ 'C:\Users\Dat-Thanh\Documents\MATLAB\geometric_video.mov' ];
  % moviename2 = [ PsychtoolboxRoot 'PsychDemos\MovieDemos\DualDiscs.mov' ]
  moviename2 = [ 'C:\Users\Dat-Thanh\Documents\MATLAB\social_video.mov' ]
   n = 'Loading Movie'
   movie = Screen('OpenMovie', w, moviename);
   movie2 = Screen('OpenMovie', w, moviename2);
   n = 'Movie Loaded'
   Screen('PlayMovie', movie, 1);
   Screen('PlayMovie', movie2, 1);
   
   movieHeight = 480;
   movieWidth = 854;
   
   scaleFactor = 2
   
   lastFrame = GetSecs;
   fps = 0;
   z = 1;
   while(true)
        texture = Screen('GetMovieImage', w, movie);
        texture2 = Screen('GetMovieImage', w, movie2);
        n = 'tex loaded';
        
        if texture<=0
            break;
        end
        if texture2<=0
            break;
        end
        
        n = 'drawing';
        x = 0;
        y = 0;
        Screen('DrawTexture', w, texture, [], [x,y, wdist/2, hdist]);
        n = 'drew';
        
        x = wdist/2;
        y = 0;
        Screen('DrawTexture', w, texture2, [], [x,y, wdist, hdist]);
        
       
        [mx, my, buttons]=GetMouse(screenNumber);
        if any(buttons)
            break;
        end
        
        if KbCheck
            break;
        end;
        
        vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
        
        Screen('Close', texture);
        Screen('Close', texture2);
        
        fps = fps + 1;
        if(GetSecs - lastFrame >= 1)
            lastFrame = GetSecs;
            fps
            fps = 0;
        end
    end;
    
    n='Done'
    WaitSecs(1);

    Screen('CloseMovie', movie);
    Screen('CloseMovie', movie2);
    
    Priority(0);
    ShowCursor
    Screen('CloseAll');

  catch ME
    ME.stack.line
    Priority(0);
    ShowCursor
    Screen('CloseAll');
 end
