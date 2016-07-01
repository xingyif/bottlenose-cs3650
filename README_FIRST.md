06/24/2016
==========

Overview
--------

Finished removing staff pages, and fixing up the links. Things that didn't work
before like team creation, registration creation, and more all work again.

To Do
-----

- [ ] Add uniform edit pages for each resource.
- [x] Add permissions for every page.

06/29/2016
==========

Overview
--------

I've confirmed that registration management, and team management works as
intended. Tarballs of submissions are now also implemented for download, and
view ing contents on submission show page.

There is a line that concerns me in app/models/submission.rb

    return if student_notes == "@@@skip tests@@@"

I'm working on getting the expectations from script/grade-submission and the
grader scripts that Ben provided to mesh.

Right now the system works by calling `grade!` on a submission, which kicks off
`script/grade-submission` on the corresponding submission. This in turn, untars
and runs `test.sh` from within the grading tarball. An example of this can be
found in `hw1/` from this directory. Keep in mind that the grading file is an
upload attached to the assignment, which needs to be un-archived.

The way building works now is unlikely to work well with concurrent requests.

To Do
-----

- [x] Need an edit link for assignments.

06/30/2016
==========

Overview
--------

I've added links for more actions based on what permissions you should have,
and I made the actions check permissions to prevent students from creating
assignments for example.

I've been playing with the needed changes to the new TAP parser, and test.sh
runner. The way the temporary directories are made and test.sh is run is
currently not working as intended.
