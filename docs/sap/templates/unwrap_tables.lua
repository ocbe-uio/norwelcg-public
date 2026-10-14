-- unwrap_tables.lua — docx only. Quarto wraps each captioned (cross-referenced)
-- table and figure in a one-column layout table; with the bordered "Table"
-- style of sap_reference.docx that wrapper would be drawn as a box around
-- caption and table. Replace the wrapper by its content (the Div holding the
-- caption and the table or figure).
function Table(t)
  if not FORMAT:match("docx") then return nil end
  if #t.colspecs ~= 1 or #t.head.rows ~= 0 or #t.bodies ~= 1 then return nil end
  local rows = t.bodies[1].body
  if #rows ~= 1 or #rows[1].cells ~= 1 then return nil end
  local blocks = rows[1].cells[1].contents
  if #blocks == 1 and blocks[1].t == "Div" then return blocks end
end
