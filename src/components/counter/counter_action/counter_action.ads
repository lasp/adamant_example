-- An action to perform when the count is
-- updated.
with Interfaces; use Interfaces;
package Counter_Action is
   procedure Do_Action (Count : in Unsigned_32);
end Counter_Action;
