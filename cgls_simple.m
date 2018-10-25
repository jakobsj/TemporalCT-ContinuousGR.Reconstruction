function x = cgls_simple(A,b,k)
%CGLS Conjugate gradient algorithm applied implicitly to the normal equations.
%
% x = cgls(A,b,k)
%
% Performs k steps of the conjugate gradient algorithm applied
% implicitly to the normal equations A'*A*x = A'*b.
%
% References: A. Bjorck, "Numerical Methods for Least Squares Problems",
% SIAM, Philadelphia, 1996.
% C. R. Vogel, "Solving ill-conditioned linear systems using the
% conjugate gradient method", Report, Dept. of Mathematical
% Sciences, Montana State University, 1987.

% Per Christian Hansen, IMM, July 23, 2007.

% Modified by Jakob S. Jorgensen, University of Manchester, 2018 
% from cgls.m in Regularization Tools 4.1 by Per Christian Hansen,
% available from http://www.imm.dtu.dk/~pcha/Regutools/

t_acc = tic;
fprintf('Started cgls_simple...\n');

% Initialization.
if (k < 1), error('Number of steps k must be positive'), end

[~,n] = size(A);

% Prepare for CG iteration.
x = zeros(n,1,'single');
d = A'*b;
r = b;
clear b;
normr2 = d'*d;

% Iterate.
for j=1:k
  
  fprintf('It %d/%d: FP=',j,k)
  t_fp = tic;
  % Update x and r vectors.
  Ad = A*d;
  time_fp = toc(t_fp);
  fprintf('%.1fs. ',time_fp);
  alpha = normr2/(Ad'*Ad);
  x  = x + alpha*d;
  r  = r - alpha*Ad;
  fprintf('BP=');
  t_bp = tic;
  s  = A'*r;
  time_bp = toc(t_bp);
  fprintf('%.1fs. ', time_bp);

  % Update d vector.
  normr2_new = s'*s;
  beta = normr2_new/normr2;
  normr2 = normr2_new;
  d = s + beta*d;
  fprintf('It: %.1fs. ',toc(t_fp));
  fprintf('Ac: %.1fs.\n',toc(t_acc));

end