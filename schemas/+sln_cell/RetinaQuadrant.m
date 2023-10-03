function q = RetinaQuadrant()

q = proj(sln_symphony.ExperimentCell * sln_animal.Eye * sln_cell.Cell,'*', ...
            'IF((x = 0 AND y = 0) OR (side LIKE "Unknown%"), null, IF((side = "Left" AND x < 0) OR (side = "Right" AND x > 0), IF(y < 0, "VT", "DT"),  IF(y < 0, "VN", "DN"))) -> quadrant');
