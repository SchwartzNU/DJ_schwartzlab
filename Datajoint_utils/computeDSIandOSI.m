function R = computeDSIandOSI(anglesDeg, responseMagnitudes)

%DSI, DSang, OSI, OSang;
anglesRad = deg2rad(anglesDeg);

% Vector DSI and OSI
responseSum = sum(responseMagnitudes);
responseVectorSumDir = sum(responseMagnitudes .* exp(sqrt(-1) * anglesRad));
responseVectorSumOrth = sum(responseMagnitudes .* exp(sqrt(-1) * anglesRad * 2));

R.DSI = abs(responseVectorSumDir / responseSum);
R.OSI = abs(responseVectorSumOrth / responseSum);
R.DSang = rad2deg(angle(responseVectorSumDir / responseSum));
R.OSang = rad2deg(angle(responseVectorSumOrth / responseSum)) / 2;

if R.DSang < 0
    R.DSang = 360 + R.DSang;
end

if R.OSang < 0
    R.OSang = 360 + R.OSang;
end

R.OSang = mod(R.OSang,180); %OSangles should be between [0,180]

% directional variance
R.DVar = var(responseMagnitudes ./ mean(responseMagnitudes));

% Max response vs min response:
compare = @(a,b) (abs(a)-abs(b))./(abs(a)+abs(b));

[~, prefInd] = max(abs(responseMagnitudes));
prefAngle = anglesDeg(prefInd);
nullAngle = rem(prefAngle+180,360); % for DS
[~, nullInd] = min(abs(anglesDeg - nullAngle));
if length(nullInd) > 1
    nullInd = nullInd(1);
end

R.DSI_pref_null = compare(abs(responseMagnitudes(prefInd)), abs(responseMagnitudes(nullInd)));

[~, prefInd1] = max(abs(responseMagnitudes));
prefAngle1 = anglesDeg(prefInd1);
prefAngle2 = rem(prefAngle+180, 360); % opposite side
nullAngle1 = rem(prefAngle1+90, 360); % for OS
nullAngle2 = rem(prefAngle1+270, 360); % for OS
[~, prefInd2] = min(abs(anglesDeg - prefAngle2));
[~, nullInd1] = min(abs(anglesDeg - nullAngle1));
[~, nullInd2] = min(abs(anglesDeg - nullAngle2));

if length(prefInd2) > 1
    prefInd2 = prefInd2(1);
end
if length(nullInd1) > 1
    nullInd1 = nullInd1(1);
end
if length(nullInd2) > 1
    nullInd2 = nullInd2(1);
end

prefResp = mean([abs(responseMagnitudes(prefInd1)), abs(responseMagnitudes(prefInd2))]);
nullResp = mean([abs(responseMagnitudes(nullInd1)), abs(responseMagnitudes(nullInd2))]);

R.OSI_pref_null = compare(prefResp, nullResp);
