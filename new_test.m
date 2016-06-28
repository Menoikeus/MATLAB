
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
    center_dot_radius = 20;
    box_size = 85;
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
    
    fix_cord = [center-center_dot_radius center+center_dot_radius];
    box_x = randi([0,1920], 1, 1);
    box_y = randi([0,1080], 1, 1);
    box_coord = [box_x box_y box_x+box_size box_y+box_size];
 
    orig_cord = fix_cord;
    
    disp('RECT HEIGHT')
    disp(RectHeight(rect))
    disp('RECT WIDTH')
    disp(RectWidth(rect))
    
    rect_h = RectHeight(rect);
    rect_w = RectWidth(rect);
    
    hdist = rect_h;
    wdist = rect_w;
     
   start_time = GetSecs;
   while(GetSecs - start_time < 20)
        DrawFormattedText(w, 'INSTRUCTIONS', 'center', 390, white);
        DrawFormattedText(w, 'You will now participate in a test designed to examine your ability to make saccades away from an object', 'center', 440, white);
        DrawFormattedText(w, 'In this exercise, you will be looking at a white dot at the center of the screen', 'center', 470, white);
        DrawFormattedText(w, 'When a colored square appears, direct your gaze at it', 'center', 500, white);
        DrawFormattedText(w, 'When the colored square disappears, return your gaze to the center dot', 'center', 530, white);
        DrawFormattedText(w, ['The test will begin in ' num2str(round(20-(GetSecs-start_time))) ' seconds'] , 'center', 580, white);
        DrawFormattedText(w, '(or press any key to skip)' , 'center', 610, white);
        Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
        
        % get key/mouse press to skip introduction screen
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
   
   %dot stuff
   dot_count = 40;
   dot_radius = 30;
   deviation = 25;
   speed = 10;
   x = randi([0,wdist],dot_count, 1);
   y = randi([0,hdist],dot_count, 1);
   xy = [x y]
   
   dot_directions = (2*pi).*rand(dot_count,1)
   
   rgb_color_dots = round(randi([100, 200],3,dot_count)); 
    
   
   Line1 = GetSecs;
   Line2 = Line1+5;  
   x = 1;
   rgb_color = round(randi([0, 255],3,1)); 
   for i = 1:nframes
       Line1 = GetSecs;
       if (i>1)
           if(mod(i,1) == 0)
               for z = 1:dot_count
                   %{
                   g = randi([-1 * deviation,deviation],1,2);
                   xy(z,1) = xy(z,1) + g(1);
                   xy(z,2) = xy(z,2) + g(2);
                   %}
                   xy(z,1) = xy(z,1) + speed * cos(dot_directions(z));
                   xy(z,2) = xy(z,2) + speed * -1 * sin(dot_directions(z));
                   if(xy(z,1) < 0)
                       xy(z,1) = 0;
                       dot_directions(z) = pi - dot_directions(z);
                   end
                   if(xy(z,1) > wdist)
                       xy(z,1) = wdist;
                       dot_directions(z) = pi - dot_directions(z);
                   end
                   if(xy(z,2) < 0)
                       xy(z,2) = 0;
                       dot_directions(z) = 2 * pi - dot_directions(z);
                   end
                   if(xy(z,2) > hdist)
                       xy(z,2) = hdist;
                       dot_directions(z) = 2 * pi - dot_directions(z);
                   end
               end
           end
           
            if (mod(i,240) == 0)
                h(1,2) = randi([-1000,1000],1,1);
                leaning = ((box_coord(1,1)/rect_w) - .5);
                round([-500 + -1200 * leaning, 500 + -1200 * leaning]);
                h(1,1) = randi(round([-500 + -2000 * leaning, 500 + -2000 * leaning]), 1, 1);

                while any(abs(h) < 300)
                    h = randi([-1000,1000],1,2);
                end

                rgb_color = round(randi([0, 255],3,1)); 
                while(any(rgb_color < 100) || any(rgb_color > 200))
                    rgb_color = round(randi([0, 255],3,1)); 
                end
               box_coord = box_coord + [h(1,1) h(1,2) h(1,1) h(1,2)]; 
            end

            %check validity
            if(box_coord(1,1) > wdist - box_size)
                box_coord(1,3) = box_coord(1,3) - (box_coord(1,1) - (wdist- box_size)); 
                box_coord(1,1) = wdist- box_size;
                disp('hit right')
            end
            if(box_coord(1,1) < 0)
                box_coord(1,3) = box_coord(1,3) - box_coord(1,1);
                box_coord(1,1) = 0;
                disp('hit left')
            end
            if(box_coord(1,2) > hdist - box_size)
                box_coord(1,4) = box_coord(1,4) - (box_coord(1,2) - (hdist-box_size));
                box_coord(1,2) = hdist - box_size;
                disp('hit bottom')
            end
            if(box_coord(1,2) < 0)
                box_coord(1,4) = box_coord(1,4) - box_coord(1,2);
                box_coord(1,2) = 0;
                disp('hit top')
            end


          if(mod(i,240) <= 239 && mod(i,240) >= 120)
            Screen('FillRect', w, uint8(rgb_color), box_coord);	% draw moving box (flip erases it)   
          end
          Screen('FillOval', w, uint8(white), fix_cord);	% draw fixation dot (flip erases it) 

          %dot stuff
          for i = 1:dot_count
              Screen('FillOval', w, uint8(rgb_color_dots(:,i)), [xy(i,1) xy(i,2) xy(i,1)+dot_radius xy(i,2)+dot_radius]);
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
        
        vbl=Screen('Flip', w, vbl + (waitframes-0.5)*ifi);
    end;

    Priority(0);
    ShowCursor
    Screen('CloseAll');

  catch ME
    ME.stack.line
    Priority(0);
    ShowCursor
    Screen('CloseAll');
 end
