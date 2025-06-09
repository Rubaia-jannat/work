function Animate_pendulum()
    % Parameters
    z0 = 100;                    % Mean thermocline depth (m)
    A = 10;                      % Oscillation amplitude (m)
    T = 12 * 3600;               % Period (12 hours)
    omega = 2 * pi / T;
    dt = 300;                    % Time step (5 min)
    total_time = 2 * 24 * 3600;  % Simulate 2 days
    t = 0:dt:total_time;

    % Domain
    z_min = 0; z_max = 200;      % Depth range
    x_min = 0; x_max = 10;       % Horizontal range (km)

    % Temperature parameters
    surface_temp = 28;
    deep_temp = 4;
    scale_surface = 7;
    scale_deep = 15;

    % Grids
    z = linspace(z_min, z_max, 200)';
    x = linspace(x_min, x_max, 100);
    [X, Z] = meshgrid(x, z);

    % Create figure
    fig = figure('Name', 'Realistic Thermocline Oscillation', 'NumberTitle', 'off', 'Color', 'w');
    colormap(turbo)
    hold on
    set(gca, 'YDir', 'reverse')
    ylim([z_min z_max])
    xlim([x_min x_max])
    xlabel('Horizontal distance (km)')
    ylabel('Depth (m)')
    title('Thermocline Oscillation with Temperature Profile')
    grid on

    % Seabed
    fill([x_min x_max x_max x_min], [z_max z_max z_max+5 z_max+5], [0.6 0.4 0.2], 'EdgeColor','none')

    % Initial thermocline
    z_thermo = z0 * ones(size(x));

    % Initial temperature field
    temp = compute_temp(Z, repmat(z_thermo, length(z), 1), surface_temp, deep_temp, scale_surface, scale_deep);
    h_temp = imagesc(x, z, temp, 'AlphaData', 0.9);
    set(gca, 'YDir', 'reverse')
    c = colorbar;
    c.Label.String = 'Temperature (°C)';
    clim([deep_temp surface_temp]);

    % Thermocline line
    h_thermo = plot(x, z_thermo, 'w-', 'LineWidth', 2);

    % 🎥 Set up video writer
    v = VideoWriter('thermocline_animation.mp4', 'MPEG-4');
    v.FrameRate = 10;  % Adjust as needed
    open(v);

    % Animation loop
    for i = 1:length(t)
        time = t(i);

        % Thermocline shape with internal wave patterns
        tide = A * sin(omega * time);
        wave1 = 5 * cos(2 * pi * x / 5 + omega * time);
        wave2 = 3 * sin(2 * pi * x / 2.5 + omega * time / 2);
        wave3 = 2 * sin(2 * pi * x / 1.7 - omega * time / 1.5);
        z_thermo = z0 + tide + wave1 + wave2 + wave3;

        % Add smoothed noise
        noise = movmean(randn(size(x)) * 0.5, 7);
        z_thermo = z_thermo + noise;

        % Update temperature field
        temp = compute_temp(Z, repmat(z_thermo, length(z), 1), surface_temp, deep_temp, scale_surface, scale_deep);
        set(h_temp, 'CData', temp);
        set(h_thermo, 'YData', z_thermo);

        % Timestamp (optional text)
        timestamp = sprintf('Time: %.1f hr', time/3600);
        tbox = text(x_max-1.8, z_min+10, timestamp, 'FontSize', 12, 'FontWeight', 'bold', ...
            'Color', 'w', 'BackgroundColor', 'k');

        drawnow;
        frame = getframe(fig);
        writeVideo(v, frame);
        delete(tbox);  % remove timestamp before next frame
    end

    close(v);
    disp('Animation saved as thermocline_animation.mp4');
end

function temp = compute_temp(Z, z_thermocline, surface_temp, deep_temp, scale_surface, scale_deep)
    % Computes temperature field based on thermocline depth
    temp = zeros(size(Z));
    ind_surf = Z <= z_thermocline;
    ind_deep = Z > z_thermocline;

    temp(ind_surf) = surface_temp - (surface_temp - deep_temp) * ...
        0.5 * (1 + erf((Z(ind_surf) - z_thermocline(ind_surf)) / scale_surface));

    temp(ind_deep) = deep_temp + (surface_temp - deep_temp) * ...
        0.5 * (1 - erf((Z(ind_deep) - z_thermocline(ind_deep)) / scale_deep));
end
