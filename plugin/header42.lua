vim.api.nvim_create_user_command("Stdheader", function(args)
  if args.bang then
    require("header42").insert()
  else
    require("header42").update()
  end
end, { desc = "Update (or insert) the Codam header", bang = true })
