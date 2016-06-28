
AssertOpenGL;

showSprites = [];

waitframes = [];

%if nargin < 1
    
    
 %   showSprites = [];
%end

if isempty(showSprites)
    showSprites = 0;
end

%if nargin < 2
 %   waitframes = [];
%end

if isempty(waitframes)
    waitframes = 1;
end

try

    % ------------------------
    % set dot field parameters
    % ------------------------

    nframes     = 3600; % number of animation frames in loop
    mon_width   = 28;   % horizontal dimension of viewable screen (cm)
    v_dist      = 75;   % viewing distance (cm)
    if showSprites > 0
        dot_speed   = 0.04; % dot speed (deg/sec) - Take it sloooow.
        f_kill      = 0.00; % Don't kill (m)any dots, so user can see better.
    else
        dot_speed   = 7;    % dot speed (deg/sec)
        f_kill      = 0.03; % fraction of dots to kill each frame (limited lifetime)
    end
    ndots       = 70; % number of dots
    max_d       = 12;   % maximum radius of  annulus (degrees)
    min_d       = 1;    % minumum
    dot_w       = 0.3;  % width of dot (deg)
    fix_r       = 0.4; % radius of fixation point (deg)
    differentcolors =1; % Use a different color for each point if == 1. Use common color white if == 0.
    differentsizes = 0; % Use different sizes for each point if >= 1. Use one common size if == 0.
    
   % waitframes = 1;     % Show new dot-images at each waitframes'th monitor refresh.
    
    if differentsizes>0  % drawing large dots is a bit slower
        ndots=round(ndots/5);
    end
    
    % ---------------
    % open the screen
    % ---------------

    screens=Screen('Screens');
	screenNumber=max(screens);
    [w, rect] = Screen('OpenWindow', screenNumber, 0);
    

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

    ppd = pi * (rect(3)-rect(1)) / atan(mon_width/v_dist/2) / 360;    % pixels per degree
    pfs = dot_speed * ppd / fps;                            % dot speed (pixels/frame)
    s = dot_w * ppd;                            % dot size (pixels)
    
    fix_cord = [center-fix_r*ppd center+fix_r*ppd];

    rmax = max_d * ppd;	% maximum radius of annulus (pixels from center)
    rmin = min_d * ppd; % minimum
    r = rmax * sqrt(rand(ndots,1));	% r
    r(r<rmin) = rmin;
    t = 2*pi*rand(ndots,1);                     % theta polar coordinate
    cs = [cos(t), sin(t)];
    xy = [r r] .* cs;   % dot positions in Cartesian coordinates (pixels from center)

    mdir = 2 * floor(rand(ndots,1)+0.5) - 1;    % motion direction (in or out) for each dot
    dr = pfs * mdir;                            % change in radius per frame (pixels)
    dxdy = [dr dr] .* cs;                       % change in x and y per frame (pixels)

    % Create a vector with different colors for each single dot, if
    % requested:
    if (differentcolors==1)
        colvect = uint8(round(rand(3,ndots)*255))
    else
        colvect=white;
    end;
    
    % Create a vector with different point sizes for each single dot, if
    % requested:
    if (differentsizes>0)
        s = (1+rand(1, ndots)*(differentsizes-1))*s;
        s = max(s, 1);
    end;
    
    
    orig_cord = fix_cord;

    %{
    peramTL = fix_cord + [400 400 400 400];

    peramBR = fix_cord + [-400 -400 -400 -400];

    peramTR = fix_cord + [-400 400 400 400]; %% Currently not working

    peramBL = fix_cord + [400 -400 400 400]; %% Currently not working
    %}
    
    disp('RECT HEIGHT')
    disp(RectHeight(rect))
    disp('RECT WIDTH')
    disp(RectWidth(rect))
    
    rect_h = RectHeight(rect);
    rect_w = RectWidth(rect);
    
    %{
     peramTL = fix_cord + [rect_w, rect_h/2, rect_w, rect_h];

    peramBR = fix_cord + [-1 * rect_w, -1 * rect_h/2, rect_w, rect_h];

    peramTR = fix_cord + [-1 * rect_w, rect_h/2, rect_w, rect_h]; %% Currently not working

    peramBL = fix_cord + [rect_w, -1 * rect_h/2, rect_w, rect_h]; %% Currently not working
    %}
    
    hdist = rect_h;
    wdist = rect_w;
    

    
    Line1 = GetSecs;

    Line2 = Line1+5;

 
    % --------------
    % animation loop
    % --------------    
    
   
    start_time = GetSecs;
   while(GetSecs - start_time < 20)
        DrawFormattedText(w, 'INSTRUCTIONS', 'center', 390, white);
        DrawFormattedText(w, 'You will now participate in a test designed to examine your ability to fixate on an object', 'center', 440, white);
        DrawFormattedText(w, 'In this exercise, you will be looking at a white dot at the center of the screen', 'center', 470, white);
        DrawFormattedText(w, 'Maintain your gaze on that white dot', 'center', 500, white);
        DrawFormattedText(w, 'Try to prevent yourself from looking at the moving colored dots', 'center', 530, white);
        DrawFormattedText(w, ['The test will begin in ' num2str(round(20-(GetSecs-start_time))) ' seconds'] , 'center', 580, white);
        DrawFormattedText(w, '(or press any key to skip)' , 'center', 610, white);
        Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
        
        [mx, my, buttons]=GetMouse(screenNumber);
        if any(buttons)
            break;
        end
        
        if KbCheck
            break;
        end;
        
        vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
   end
   
   Screen(w,'FillRect', [0 0 0]);
   vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
   WaitSecs(1);
    
   for i = 1:nframes
        Line1 = GetSecs;
        h = randi([-400,400],1,2);
        
        while any(abs(h) < 300)
            h = randi([-400,400],1,2);
        end
        
       % Moving the center dot every 180 frames
       if (i>1)
            
          %{
          if (fix_cord >= peramTL) % If the fixation reaches a certain point in the top left, it is brought back to its starting position
              fix_cord = orig_cord;
          end

          if (fix_cord <= peramBR) % If the fixation reaches a certain point in the Bottom Right, it is brought back to its starting position
              fix_cord = orig_cord;

          end

          
          if (fix_cord > peramTR)
              fix_cord = orig_cord;
          end

          if (fix_cord < peramBL)
              fix_cord = orig_cord;
          end
            %}
            if (mod(i,120) == 0)
               if (Line1<Line2)  % Distinguishes which way the dot shall move
                 % Moves the Fixation point on the line where m = -1
                  fix_cord = fix_cord + [h(1,1) h(1,2) h(1,1) h(1,2)]; 
               else % Moves the Fixation point on the line where m = 1
                fix_cord = orig_cord;
                fix_cord = fix_cord + [h(1,1)*-1 h(1,2) h(1,1)*-1 h(1,2)];
                Line2 =GetSecs+5;
               end
               disp('Coordinates: ')
               disp(fix_cord)
            end
           
            %check validity
            if(fix_cord(1,1) > wdist - fix_r*ppd)
                fix_cord(1,3) = fix_cord(1,3) - (fix_cord(1,1) - (wdist- fix_r*ppd)); 
                fix_cord(1,1) = wdist- fix_r*ppd;
                disp('hit right')
            end
            if(fix_cord(1,1) < 0)
                fix_cord(1,3) = fix_cord(1,3) - fix_cord(1,1);
                fix_cord(1,1) = 0;
                disp('hit left')
            end
            if(fix_cord(1,2) > hdist - fix_r*ppd)
                fix_cord(1,4) = fix_cord(1,4) - (fix_cord(1,2) - (hdist-fix_r*ppd));
                fix_cord(1,2) = hdist - fix_r*ppd;
                disp('hit bottom')
            end
            if(fix_cord(1,2) < 0)
                fix_cord(1,4) = fix_cord(1,4) - fix_cord(1,2);
                fix_cord(1,2) = 0;
                disp('hit top')
            end
           
           
           
          Screen('FillOval', w, uint8(white), fix_cord);	% draw fixation dot (flip erases it)   
          
          if showSprites
                % Draw little "sprite textures" instead of dots:
                PsychDrawSprites2D(w, tex, xymatrix, s, angles, colvect, center, 1);  % change 1 to 0 to draw unfiltered sprites.
          else
                % Draw nice dots:
              Screen('DrawDots', w, xymatrix, s, colvect, center,1);  % change 1 to 0 to draw square dots  
          end
          
            Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
        end;
    
         % Break out of animation loop if any key on keyboard or any button
        % on mouse is pressed:
        [mx, my, buttons]=GetMouse(screenNumber);
        if any(buttons)
            break;
        end
        
        if KbCheck
            break;
        end;
        
        xy = xy + dxdy;						% move dots
        r = r + dr;							% update polar coordinates too

       
        % check to see which dots have gone beyond the borders of the annuli

        % EXPERIMENTAL ZONE
        
        
        r_out = find(r > rmax | r < rmin | rand(ndots,1) < f_kill);	% dots to reposition
      %  r_out = find(xy(1) > 1920 | xy(1) < 0 | rand(ndots,1) < f_kill);
       nout = length(r_out);

        if nout

            % choose new coordinates
            r(r_out) = rmax * sqrt(rand(nout,1));
            r(r<rmin) = rmin;
            t(r_out) = 2*pi*(rand(nout,1));

            
            % now convert the polar coordinates to Cartesian

            cs(r_out,:) = [cos(t(r_out)), sin(t(r_out))];
            xy(r_out,:) = [r(r_out) r(r_out)] .* cs(r_out,:);

            % compute the new cartesian velocities

            dxdy(r_out,:) = [dr(r_out) dr(r_out)] .* cs(r_out,:);
        end;
        xymatrix = transpose(xy);
        
        vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
    end;
          
    Disp('Test completed');
    
    Priority(0);
    ShowCursor
    Screen('CloseAll');
  catch ME
    ME.stack.line
    Priority(0);
    ShowCursor
    Screen('CloseAll');
 end
