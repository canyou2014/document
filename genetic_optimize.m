%%Genetic Algorithm
%%
%domain 参数范围 size = n x 2
function genetic_optimize(domain)
    maxiter = 50; popsize = 30; len_v = 10;topelite = 12; % parameter
	pop = zeros(popsize, len_v);
	for i = 1:popsize %initial
		for j = 1:len_v
			pop(i,j) = rand(1,1) * (domain(j,2) - domain(j,1)) + domain(j,1);		
		end		
    end

		scores = zeros(popsize, 1);
        indexd = zeros(popsize, 1);
	for i = 1:maxiter % max iter
		for p = 1:pop
			scores(p) = costf(pop(p, :));%cell						
        end
        
		[scores, indexd] = sort(scores); % sort pop 
		for r  = 1:topelite
			
			new_pop(r, :) = pop(indexd(r), :); 	
        	
		end
		pop = new_pop;
		while length(pop) < popsize
			if rand(1,1) < mutprob
				c = rand(1,1)*topelite;
				pop(end+1, :) = mutate(pop(c, :));			
			else
				c1 = rand(1,1)*topelite;
				c2 = rand(1,1)*topelite;
				pop(end+1, :) = crossover(pop(c1, :), pop(c2, :));
			end
			
		end
		print scores(1, 1);
	end
end
%%
%cost function
function score = costf(vec)
    x = INS(u, vec);
    score = x(1,end)^2 + x(2, end)^2 + (max(x(1,:)) - max_x)^2 + (max(x(2,:)) - max_y)^2;
end
%%
%variation
function para_out = mutate(vec)
	i = round(rand(1,1)*len_v); % 1~len
	if rand(1,1) < 0.5 && vec(i) > domain(i,1)
		para_out(i) = vec(i) + 1;
	else if vec(i) < domain(i,2)
		para_out(i) = vec(i) - 1;	
	end
    end
end
%%
%cross
function para_out = crossover(r1, r2) 
	i = round(rand(1,1)*(len_v-2)) + 1; % 2~len-1
	para_out(1:i) = r1(1:i);
	para_out(i+1:len_v) = r2(i+1:len_v);
end
%%
