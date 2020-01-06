function plot_quick_tc(intc,runs)

% get design parameters
nexps = 3;
nses= size(intc, 2);
tc_min=min(min(cell2mat(intc)));
tc_max=max(max(cell2mat(intc)));
% setup figure

counter=1;
conseq = @(x,n) (n*x)-(n-1);
for ss = 1:nses   

    for ee = 1:nexps
        pIdx=conseq(ee,nexps);
        subplot(nexps,nses,counter);
        
        if runs== 1
            plot(intc{pIdx,ss}, 'LineWidth', 1); hold on;
        elseif runs==2
            plot(intc{pIdx,ss}, 'LineWidth', 1); hold on;
            plot(intc{pIdx+1,ss}, 'LineWidth', 1); hold on;
        else
            plot(intc{pIdx,ss}, 'LineWidth', 1); hold on;
            plot(intc{pIdx+1,ss} , 'LineWidth', 1); hold on;
            plot(intc{pIdx+2,ss} , 'LineWidth', 1); hold on;
        end
        
        counter=counter+1;
        ylim([tc_min,tc_max]);
    end
    
end



end
