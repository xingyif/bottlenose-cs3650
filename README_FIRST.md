06/24/2016
==========

Overview
--------

Finished removing staff pages, and fixing up the links. Things that didn't work
before like team creation, registration creation, and more all work again.

To Do
-----

- [ ] Add uniform edit pages for each resource.
- [ ] Add permissions for every page.

06/29/2016
==========

Overview
--------

I've confirmed that registration management, and team management works as
intended. Tarballs of submissions are now also implemented for download, and
view ing contents on submission show page.

There is a line that concerns me in app/models/submission.rb

    return if student_notes == "@@@skip tests@@@"

To Do
-----

- [ ] Need an edit link for assignments.
