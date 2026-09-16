classdef Projectome_Util
methods (Static)
    function total_c = match_overview(pop_figure)

        % %total cell type and axon count
        arguments
            pop_figure = false;
        end
        matches = fetch(sln_cell.CellAxonMatch);
    end
end
end