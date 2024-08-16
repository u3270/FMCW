clear;clc;close all;

% parse training file
training_folder = ('./../measured_data/knu_museum_240106/training');
flist = dir([training_folder, '/sensor*.txt']);

for i=1:length(flist)
    curr_filename = [flist(i).folder, '/', flist(i).name];
    %curr_filename = curr_filename(1:end-4);
    
    parse_and_sync_sensor_data(curr_filename);
    
end

function parse_and_sync_sensor_data(file_path)
    % 파일 열기
    fid = fopen(file_path, 'r');
    
    % 데이터 배열 초기화
    acc_data = [];
    acc_synced = [];
    gyro_data = [];
    gyro_synced = [];
    acc_synced1= [];
    game_rot_vec_data = [];
    game_rot_vec_data_synced = [];
    
    % 데이터 추출
    while ~feof(fid)
        line = fgetl(fid);
        
        if contains(line, 'ACC')
            % ACC 데이터 파싱
            data = sscanf(line, 'ACC, %f, %f, %f, %f, %f');
            acc_data = [acc_data; data([1, 3, 4, 5])'];

        elseif contains(line, 'GYRO')
            % GYRO 데이터 파싱
            data = sscanf(line, 'GYRO, %f, %f, %f, %f, %f');
            gyro_data = [gyro_data; data([1, 3, 4, 5])'];

        elseif contains(line, 'GAME_ROT_VEC')
            % GAME_ROT_VEC 데이터 파싱
            data = sscanf(line, 'GAME_ROT_VEC, %f, %f, %f, %f, %f, %f');
            game_rot_vec_data = [game_rot_vec_data; data([1, 3, 4, 5, 6])'];
  
        end
    end
    
    % 파일 닫기
    fclose(fid);
    
    time = game_rot_vec_data(:,1);
    acc_time = acc_data(:,1);
    gyro_time = gyro_data(:,1);
    
    % 시간동기화된 ACC 데이터 추출
    for i = 1:length(acc_time)
            for j = 1:length(time)
                if acc_time(i,1) > time(j,1)
                    acc_synced(end+1,:) = acc_data(i-1,2:end);
                    acc_synced1(end+1,:) = acc_data(i-1,:);
                    break
                end
                if acc_time(i,1) == time(j,1)
                    acc_synced(end+1,:) = acc_data(i,2:end);
                    acc_synced1(end+1,:) = acc_data(i-1,:);
                    break
                end
            end
    end

    % 시간동기화된 GYRO 데이터 추출
    for i = 1:length(gyro_time)
            for j = 1:length(time)
                if gyro_time(i,1) > time(j,1)
                    gyro_synced(end+1,:) = gyro_data(i-1,2:end);
                    break
                end
                if gyro_time(i,1) == time(j,1)
                    gyro_synced(end+1,:) = gyro_data(i,2:end);
                    break
                end
            end
    end

    % 시간동기화된 GAME_ROT_VEC 데이터 추출
    for i = 1:length(time)
        game_rot_vec_data_synced(end+1,:) = game_rot_vec_data(i,2:end);
    end

    
    h5_file = [file_path(1:end-4), '_v2.hdf5'];
    
    acc_synced = acc_synced';
    gyro_synced = gyro_synced';
    game_rot_vec_data_synced = game_rot_vec_data_synced';
    acc_synced1 = acc_synced1';
    time = time';

    % HDF5 파일에 시간동기화된 데이터 저장
    h5create(h5_file, '/synced/acce', size(acc_synced));
    h5write(h5_file, '/synced/acce', acc_synced);
    
    h5create(h5_file, '/synced/gyro_uncalib', size(gyro_synced));
    h5write(h5_file, '/synced/gyro_uncalib', gyro_synced);
    
    h5create(h5_file, '/synced/game_rv', size(game_rot_vec_data_synced));
    h5write(h5_file, '/synced/game_rv', game_rot_vec_data_synced);

    h5create(h5_file, '/synced/time', size(time));
    h5write(h5_file, '/synced/time', time);
    
    h5create(h5_file, '/pose/tango_pos', size(acc_synced));
    h5write(h5_file, '/pose/tango_pos', acc_synced);

    h5create(h5_file, '/pose/tango_ori', size(acc_synced1));
    h5write(h5_file, '/pose/tango_ori', acc_synced1);

    fprintf('Data has been saved to %s\n', h5_file);

end




