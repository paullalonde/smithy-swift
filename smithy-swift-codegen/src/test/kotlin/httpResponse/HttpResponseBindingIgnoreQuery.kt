package httpResponse

import MockHttpRestJsonProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class HttpResponseBindingIgnoreQuery {

    @Test
    fun `001 Output httpResponseBinding sets query to nil`() {
        val context = setupTests("http-query-payload.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJson/models/IgnoreQueryParamsInResponseOutputResponse+HttpResponseBinding.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension IgnoreQueryParamsInResponseOutputResponse: HttpResponseBinding {
                public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {
                    self.baz = nil
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
