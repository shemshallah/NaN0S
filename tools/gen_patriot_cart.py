#!/usr/bin/env python3
# SCAFFOLD: emit the Patriot Missile Failure exhibit cartridge.
# Runtime is NaN16 (text pager). No real flight software is shipped.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_about_carts as about

LINES = [
" NaN/0S - THE PATRIOT MISSILE FAILURE",
" DHAHRAN, SAUDI ARABIA - 25 FEBRUARY 1991",
"",
" WHAT HAPPENED",
" A Patriot air-defence battery failed to intercept a Scud missile.",
" The missile struck a barracks in Dhahran. Twenty-eight soldiers died.",
" Ninety-eight were injured. The failure was not a lack of processing",
" power. It was a lack of bits in the representation of time.",
"",
" THE CLOCK",
" The Patriot software kept time in a 24-bit fixed-point counter. The",
" counter was incremented every 0.1 second. Converting that counter to a",
" real number required a multiplication by 0.1. The multiplication was",
" truncated. The truncation was tiny: about 0.000000095 second per 0.1",
" second tick. The error accumulated. After about 100 hours of continuous",
" operation the clock was off by about 0.34 second. A Scud at roughly",
" 1.6 km/s moves about 550 metres in that time. The intercept window was",
" tens of metres. The battery looked at the wrong point in the sky.",
"",
" THE NUMBER THAT MATTERS",
" 24 bits is about 16.7 million counts. At 0.1 s per count that is about",
" 19.4 days of clock. The system had to be restarted before the error",
" grew too large. The battery had been running for about 100 hours",
" without a full restart. That was inside the allowed operating time.",
" The error was not supposed to matter yet. It did.",
"",
" THE PEOPLE",
" The 28 soldiers killed at Dhahran, 25 February 1991. Status: DEAD.",
" Theodore A. Postol, 1946-, MIT physicist who publicly analysed the",
" failure and the software. Status: LIVING.",
" The U.S. Army Patriot Project Office and the Raytheon team. The",
" software authors are not named in the public record. Status: not",
" listed here, and not guessed.",
"",
" WHY IT IS A MUSEUM PIECE",
" This is a tragedy of representation. The system did not lack",
" processing power. It lacked the bits to represent time accurately.",
" Here, in a NaN machine, we have many ways to represent 'undefined'.",
" The Patriot had none. A coordinate that could not be computed became",
" a wrong number, not a refusal.",
"",
" THE TUTORIAL",
" The exhibit would render a tracking display. A clock ticks in 0.1 s",
" units. A 24-bit counter is converted to seconds with truncation. The",
" drift is accumulated and multiplied by the target speed. The predicted",
" intercept point slides away from the true point. When the range error",
" exceeds the intercept window, the coordinate is replaced by a NaN word",
" and the display prints !G. The visitor sees the failure as a number,",
" not as a story. The plaque is the source. The simulation is the lesson.",
"",
" THE PLAQUE",
" This exhibit is a tragedy of representation. The system didn't lack",
" processing power, it lacked the bits to represent time accurately.",
" Here, in a NaN machine, we have infinite ways to represent 'undefined'",
" but the Patriot had none.",
"",
" SOURCES",
" U.S. General Accounting Office, 'Patriot Missile Defense: Software",
" Problem Led to System Failure at Dhahran, Saudi Arabia', 1992.",
" Theodore A. Postol, public analysis of the Patriot software failure.",
" The 24-bit fixed-point clock and the 0.1 s tick are described in the",
" public record. The exact drift figure is approximate and is labelled",
" as such. This exhibit is a RE-CREATION, not the classified software.",
"",
" WHAT THIS EXHIBIT DOES NOT DO",
" It does not run Patriot code. It does not use classified data. It",
" does not name people who are not in the public record. It does not",
" claim that a NaN machine would have saved the soldiers. It shows the",
" shape of the failure: a small representation error, accumulated over",
" time, becomes a large error in the world.",
"",
" UP/DOWN scroll  ESC shell",
]

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    about.emit(os.path.join(root, 'src', 'exhibits', 'patriot_cart.nas'), LINES)
    print('patriot lines:', len(LINES))

if __name__ == '__main__':
    main()
