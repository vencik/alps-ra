#ifdef ALPS_PACKET_DUMP  /* dump packet to kernel ring buffer */
#define _STR(arg) #arg
#define STR(arg) _STR(arg)
    if (psmouse->pktcnt == ALPS_PACKET_SIZE) {
        psmouse_info(psmouse,
            "AlpsPS/2 packet dump: %" STR(ALPS_PACKET_SIZE) "ph\n",
            psmouse->packet);
    }
#undef STR
#undef _STR
#endif  /* end of #ifdef ALPS_PACKET_DUMP */

#ifdef ALPS_PACKET_NO_PROCESS  /* stop packet processing */
    return psmouse->pktcnt == ALPS_PACKET_SIZE
           ? PSMOUSE_FULL_PACKET : PSMOUSE_GOOD_DATA;
#endif  /* end of #ifdef ALPS_PACKET_NO_PROCESS */
