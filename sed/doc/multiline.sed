# https://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
/^a test$/{
    # append the next line when not on the last line
    $!{ N
        s/^a test\nPlease do not$/not a test\nBe/
        # now test for a successful substitution, otherwise
        #+  unpaired "a test" lines would be mis-handled

        # branch_on_substitute (goto label :sub-yes)
        t sub-yes
        # a label (not essential; here to self document)
        :sub-not
        # if no substituion, print only the first line

        # pattern_first_line_print
        P
        # pattern_ltrunc(line+nl)_top/cycle
        D
        # a label (the goto target of the 't' branch)
        :sub-yes
        # fall through to final auto-pattern_print (2 lines)
    }
}
