// MyArea.tsx
import { useMyArea } from './useMyArea';
import styles from './MyArea.module.scss'

import messiImage from '@root/public/messi.jpg'
import Otc from '@/components/Common/Otc/Otc';
import YourTokenSeccion from './YourTokenSeccion/YourTokenSeccion';
import { OTCEntityWithMetadata } from '../useHome';

export default function MyArea(props: any) {
    const { 
        tokenCardInterface
    } = useMyArea(props.listOfOtcEntityWithTokens, props.walletTokens, props.settersModalTx);

    const otcUnions = () => {
        const { otcToCancelInterface, otcToCloseInterface } = tokenCardInterface();

        const cancelElem = otcToCancelInterface?.map(token => { return { ...token, btnMod: (<button type='button' className={styles.cancel} onClick={token.btnHandler}>Cancel</button>) } })
        const closeElem = otcToCloseInterface?.map(token => {return {...token, btnMod: (<button type='button' className={styles.close} onClick={token.btnHandler}>Close</button>)}})

        return [...cancelElem, ...closeElem]
    }

    return (
        <section className={styles.myAreaSection}>
            <YourTokenSeccion settersModalTx={props.settersModalTx} walletTokens={props.walletTokens} />
            <Otc seccionCaption="Your Open OTC" tokens={otcUnions()} />
        </section>
    );
}

