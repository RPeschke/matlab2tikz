% =========================================================================
%   Copyright (c) 2012 Nico Schlömer
%   All rights reserved.
%
%   Redistribution and use in source and binary forms, with or without
%   modification, are permitted provided that the following conditions are
%   met:
%
%       * Redistributions of source code must retain the above copyright
%         notice, this list of conditions and the following disclaimer.
%       * Redistributions in binary form must reproduce the above copyright
%         notice, this list of conditions and the following disclaimer in
%         the documentation and/or other materials provided with the distribution
%
%   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%   POSSIBILITY OF SUCH DAMAGE.
% =========================================================================
function updater(name, fileExchangeUrl, version, env)
  fileExchangeUrl = m2t.website;
  name = 'matlab2tikz';
  env = m2t.env;
  version = m2t.version;
  try
      html = urlread([fileExchangeUrl, '/all_files']);
  catch %#ok
      % Couldn't load the URL -- never mind.
      html = [];
  end
  if ~isempty(html)
      % Search for a string "/version-1.6.3" in the HTML. This assumes
      % that the package author has added a file by that name to
      % to package. This is a rather dirty hack around FileExchange's
      % lack of native versioning information.
      mostRecentVersion = regexp(html, '/version-(\d+\.\d+\.\d+)', 'tokens');
      if ~isempty(mostRecentVersion)
          if isVersionBelow(env, version, mostRecentVersion{1}{1})
              userInfo(m2t, '**********************************************\n');
              userInfo(m2t, 'New version available! (%s)\n', mostRecentVersion{1}{1});
              userInfo(m2t, '**********************************************\n');

              reply = input([' *** Would you like ', name, ' to self-upgrade? y/n [n]:'],'s');
              if strcmp(reply, 'y')
                  % Download the files and unzip its contents into the folder
                  % above the folder that contains the current script.
                  % This assumes that the file structure is something like
                  %
                  %   src/matlab2tikz.m
                  %   src/[...]
                  %   AUTHORS
                  %   ChangeLog
                  %   [...]
                  %
                  % on the hard drive and the zip file. In particular, this assumes
                  % that the folder on the hard drive is writable by the user
                  % and that matlab2tikz.m is not symlinked from some other place.
                  % TODO explicitly delete the old content
                  pathstr = fileparts(mfilename('fullpath'));
                  targetPath = [pathstr, filesep, '..', filesep];
                  % Delete old version number file.
                  versionFile = [pathstr, filesep, 'version-', version];
                  if exist(versionFile, 'file') == 2
                      delete(versionFile)
                  end
                  userInfo(m2t, ['Downloading and unzipping to ', targetPath, '...']);
                  unzip([fileExchangeUrl, '?download=true'], targetPath);
                  userInfo(m2t, 'done.');
                  % TODO anything better than error()?
                  error('Upgrade successful. Please re-execute.');
              end
              userInfo(m2t, '');
          end
      end
  end
end
% =========================================================================
function isBelow = isVersionBelow(env, versionA, versionB)
  % Checks if version string or vector versionA is smaller than
  % version string or vector versionB.

  vA = versionArray(env, versionA);
  vB = versionArray(env, versionB);

  isBelow = false;
  for i = 1:min(length(vA), length(vB))
    if vA(i) > vB(i)
      isBelow = false;
      break;
    elseif vA(i) < vB(i)
      isBelow = true;
      break
    end
  end

end
% =========================================================================
function arr = versionArray(env, str)
  % Converts a version string to an array.

  if ischar(str)
    % Translate version string from '2.62.8.1' to [2, 62, 8, 1].
    if strcmpi(env, 'MATLAB')
        split = regexp(str, '\.', 'split');
    elseif strcmpi(env, 'Octave')
        split = strsplit(str, '.');
    end
    arr = str2num(char(split)); %#ok
  else
    arr = str;
  end

end
% =========================================================================
