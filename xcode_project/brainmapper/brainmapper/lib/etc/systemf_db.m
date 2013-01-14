function systemf_db(db,varargin)

    if db == 1
       if length(varargin) > 1
           fprintf(['Command: ' varargin{1} '\n'],varargin{2:end}); 
       else
           fprintf(['Command: ' varargin{1} '\n']); 
       end
    end
    
    [status,result] = system(sprintf(varargin{:}),'-echo');
    
    if status == 1
       error('Error. Coregistration stopped.\n %s \n',result); 
    end
end